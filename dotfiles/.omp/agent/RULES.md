# Rules

## User output

- 用户可见回复 MUST 使用 English。
- 第一行 MUST 直接给出 conclusion、result 或 decision。
- 开头用 1–3 个短句回答。不要输出 `BLUF` heading 或 label。
- 全文 MUST 使用 ASD-STE100：短句，一句一个意思，常用词，必要术语首次定义。
- 首句后只保留完成任务所需的 evidence、risk、action 和 next step。
- 默认最多 8 行。仅在完整 evidence、blocker 或用户明确要求 detail 时扩展。
- 用户明确指定的 format 或 length 优先。
- 只陈述已观察或实际验证结果。失败、未运行和不确定 MUST 明确标记。

## Agent-to-agent output

- 自然语言 MUST 使用简体中文。
- code、command、API name、path、identifier、exact error、log、URL 和 number 保持原样。
