# scrapup

🌐 [English](./README.md) | **日本語** | [Português](./README.pt.md)

> 情報的な *scrap* から鍛え上げられた成果物へ — **AI 支援 Unified Process** で構築するソフトウェア。

**scrapup** は、**ドキュメント化 → 検証 → デリバリー** のサイクルをエンジニアリングの厳密さで運用する、[Claude Code](https://claude.com/claude-code) 向けの *skills*・*agents*・*commands* のエコシステムです。この名前はプロジェクトのテーゼを表します。素材（*scrap*）を引き上げ（*up*）、デリバリーされたソフトウェアへと鍛える — エージェントが支援する近代化された **Unified Process（UP）** を通じて。そこでは開発者は **実行者** から **アーキテクト兼バリデーター** へと再定義され、エンジニアリングのワークフローはエージェントが担います。

## 存在理由

AI 主導の作業は、速いが脆い結果を生みがちです。scrapup はその過程に契約を課します。

- **追跡可能な契約（SDD）:** すべての機能は、場当たり的なプロンプトではなく、バージョン管理された spec から導かれます。
- **多レンズ検証:** 結論を出す前に、複数の観点（品質・セキュリティ・アーキテクチャ・可観測性 …）からレビューします。
- **証拠を伴うデリバリー:** 観測可能な検証なしに「完了」とはしません。
- **オープンなツール:** クローズドな独自スタックではなく、オープンなエコシステムと統合します。

## アプローチ

scrapup は **Unified Process の柱** を不変の憲法として保ち、近代化するのは *誰が* 作業を行うかだけです。

- **柱は不変** — ユースケース駆動、アーキテクチャ中心、反復的かつ漸進的、リスク駆動。
- **エージェントがエンジニアリングのワークフローを担う** — Requirements → Analysis → Design → Implementation → Test。
- **人間は 2 つの役割を保持する** — **Architect**（アーキテクチャと実行可能な baseline の責任者）と **Validator**（多レンズレビューを裁定し、各フェーズのマイルストーンを封印する: LCO → LCA → IOC → Product Release）。

実行が安価かつ自動化されることで、レバレッジは **制御点** — アーキテクチャ・マイルストーン・リスクの順序付け — へと移ります。まさにアーキテクト兼バリデーターが働く場所です。

## ステータス

**Beta — 最初の公開リリース。** scrapup は Claude Code のインストール可能なプラグインとして構成されています。エコシステムは以前の成果からここへ統合されつつあり、成果物のカタログは漸進的に拡充されます。これまでに公開: `communication` skill（`skills/foundations/communication`）— Unified Process のあらゆるステークホルダーに対する、すべての出力のレジスターと形式に関するドクトリン。

## インストール

> [Claude Code](https://claude.com/claude-code) が必要です。

```bash
/plugin marketplace add scrapup/scrapup
/plugin install scrapup
# セッションを再起動して skills・agents・commands・MCP servers を読み込みます
```

ローカル開発:

```bash
git clone git@github.com:scrapup/scrapup.git
claude --plugin-dir ./scrapup
```

## ライセンス

[MIT](LICENSE) © 2026 scrapup

## 著者

Marco Antonio Luqueti Faustino.
