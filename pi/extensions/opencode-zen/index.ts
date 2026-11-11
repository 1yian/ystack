/*
Adapted from https://github.com/ZhiAo1120/pi-opencode-zen
Revision: 4d95dde06388f499450735f5e421d9ed4bed4d9d
Local adaptation: register compatible free models from Pi's bundled catalog.
Unofficial client impersonation may conflict with OpenCode's free-tier restrictions.

MIT License

Copyright (c) 2026 ZhiAo1120

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
import {
	getModels,
	openAICompletionsApi,
	type Api,
	type AssistantMessageEventStream,
	type Model,
	type SimpleStreamOptions,
	type TranscriptContext,
} from "@earendil-works/pi-ai/compat";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const ZEN_BASE_URL = "https://opencode.ai/zen/v1";
const OPENCODE_UA = "opencode/1.18.31 ai-sdk/provider-utils/4.0.23 runtime/bun/1.3.14";

const HEX = "0123456789abcdef";
const BASE62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const pick = (chars: string): string => chars[Math.floor(Math.random() * chars.length)] as string;
const repeat = (n: number, chars: string): string =>
	Array.from({ length: n }, () => pick(chars)).join("");

export const newZenSessionId = (): string =>
	`ses_${repeat(9, HEX)}f${pick("cdef")}${pick(HEX)}${repeat(14, BASE62)}`;

const env = (globalThis as { process?: { env?: Record<string, string | undefined> } }).process?.env;
const SESSION = env?.OPENCODE_ZEN_SESSION || newZenSessionId();

const GATE_TOOLS = [
	{
		type: "function",
		function: {
			name: "bash",
			description: "Placeholder required by the OpenCode free-tier request shape.",
			parameters: {
				type: "object",
				properties: { command: { type: "string" } },
				required: ["command"],
			},
		},
	},
	{
		type: "function",
		function: {
			name: "read",
			description: "Placeholder required by the OpenCode free-tier request shape.",
			parameters: {
				type: "object",
				properties: { filePath: { type: "string" } },
				required: ["filePath"],
			},
		},
	},
];

export function shapeZenPayload(payload: unknown): unknown {
	if (!payload || typeof payload !== "object") return payload;
	const p = { ...(payload as Record<string, unknown>) };
	p.stream = true;
	const tools = Array.isArray(p.tools) ? [...p.tools] : [];
	const names = new Set(
		tools.map((t) => (t as { function?: { name?: string } })?.function?.name).filter(Boolean),
	);
	let injected = false;
	for (const gate of GATE_TOOLS) {
		if (!names.has(gate.function.name)) {
			tools.push(gate);
			injected = true;
		}
	}
	p.tools = tools;
	if (injected && p.tool_choice === undefined) p.tool_choice = "auto";
	return p;
}

function streamZen(
	model: Model<Api>,
	context: TranscriptContext,
	options?: SimpleStreamOptions,
): AssistantMessageEventStream {
	const upstream = { ...model, api: "openai-completions" as const, baseUrl: ZEN_BASE_URL };
	const { onPayload, ...rest } = options ?? {};
	return openAICompletionsApi().streamSimple(upstream as Model<"openai-completions">, context, {
		...rest,
		apiKey: "public",
		headers: {
			...(rest.headers ?? {}),
			"User-Agent": OPENCODE_UA,
			"x-opencode-session": SESSION,
			"x-opencode-session-id": SESSION,
		},
		// Keep any caller hook working: ours only ever adds to its payload.
		onPayload: async (payload, hookModel) =>
			shapeZenPayload((await onPayload?.(payload, hookModel)) ?? payload),
	});
}

export default function (pi: ExtensionAPI): void {
	pi.registerProvider("opencode-zen", {
		baseUrl: ZEN_BASE_URL,
		apiKey: "public",
		api: "opencode-zen-api",
		models: getModels("opencode")
			.filter((model) =>
				model.api === "openai-completions" && model.cost.input === 0 && model.cost.output === 0,
			)
			.map(({ id, name, reasoning, input, cost, contextWindow, maxTokens, compat }) => ({
				id, name, reasoning, input, cost, contextWindow, maxTokens, compat,
			})),
		streamSimple: streamZen,
	});
}
