/**
 * Chunked compaction: keeps compaction from failing when the old conversation is too big for one
 * summary request.
 *
 * Pi sends the whole span to summarize in one request, and the summary output is capped to whatever
 * room is left in the window. A session already past the trigger (a huge tool result, a resumed
 * session, a manual /compact) can leave no room, so the summary hits the token cap and compaction
 * fails. When the span will not fit with room to answer, this summarizes it in window-sized chunks,
 * folding each into the previous summary with Pi's own update prompt. Spans that fit go through
 * Pi's default path untouched.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { convertToLlm, generateSummaryWithUsage, serializeConversation } from "@earendil-works/pi-coding-agent";

// Conservative, since code and JSON tokenize worse than prose.
const CHARS_PER_TOKEN = 3;
// Summary output, the prior summary carried into each chunk, and the prompt wrapper.
const OVERHEAD_TOKENS = 48_000;
const MAX_CHUNK_TOKENS = 100_000;

const tokensOf = (m: unknown) => Math.ceil(serializeConversation(convertToLlm([m as never])).length / CHARS_PER_TOKEN);

export default function (pi: ExtensionAPI) {
	pi.on("session_before_compact", async (event, ctx) => {
		const { preparation, signal, customInstructions } = event;
		const model = ctx.model;
		const window = model?.contextWindow ?? 0;
		if (!model || window <= 0) return; // virtual (tier) models resolve their own window; use the default path

		const messages = [...preparation.messagesToSummarize, ...preparation.turnPrefixMessages];
		const sizes = messages.map(tokensOf);
		const total = sizes.reduce((a, b) => a + b, 0);
		const chunkBudget = Math.min(MAX_CHUNK_TOKENS, window - OVERHEAD_TOKENS);
		if (total <= chunkBudget || chunkBudget <= 0) return; // fits in one request: default path

		const chunks: (typeof messages)[] = [];
		let current: typeof messages = [];
		let used = 0;
		messages.forEach((m, i) => {
			if (current.length && used + sizes[i] > chunkBudget) {
				chunks.push(current);
				current = [];
				used = 0;
			}
			current.push(m);
			used += sizes[i];
		});
		if (current.length) chunks.push(current);

		const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
		if (!auth.ok) return;
		ctx.ui.notify(`Compacting ${total.toLocaleString()} tokens in ${chunks.length} chunks`, "info");

		let summary = preparation.previousSummary;
		let usage;
		for (const chunk of chunks) {
			const r = await generateSummaryWithUsage(
				chunk,
				model,
				undefined,
				auth.apiKey,
				auth.headers,
				signal,
				customInstructions,
				summary,
				pi.getThinkingLevel(),
				undefined,
				auth.env,
			);
			summary = r.text;
			usage = r.usage;
		}

		const read = new Set(preparation.fileOps.read);
		const modified = new Set([...preparation.fileOps.edited, ...preparation.fileOps.written]);
		const readFiles = [...read].filter((f) => !modified.has(f)).sort();
		const modifiedFiles = [...modified].sort();
		const sections = [
			readFiles.length ? `<read-files>\n${readFiles.join("\n")}\n</read-files>` : "",
			modifiedFiles.length ? `<modified-files>\n${modifiedFiles.join("\n")}\n</modified-files>` : "",
		].filter(Boolean);
		return {
			compaction: {
				summary: (summary ?? "") + (sections.length ? `\n\n${sections.join("\n\n")}` : ""),
				firstKeptEntryId: preparation.firstKeptEntryId,
				tokensBefore: preparation.tokensBefore,
				usage,
				details: { readFiles, modifiedFiles },
			},
		};
	});
}
