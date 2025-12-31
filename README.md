# 年末ジャンボ宝くじシミュレーター MCP Server

年末ジャンボ宝くじの購入シミュレーションを行うModel Context Protocol (MCP) サーバーです。

## 機能

- 任意の枚数の宝くじを購入した場合のシミュレーション
- 各等級の当選本数と当選金額の表示
- 購入金額と当選金額の収支計算
- 還元率の表示

## 年末ジャンボ宝くじデータ（2025年）

| 等級 | 当せん金 | 本数 |
|------|----------|------|
| 1等 | 700,000,000円 | 23本 |
| 1等前後賞 | 150,000,000円 | 46本 |
| 1等組違い賞 | 100,000円 | 4,577本 |
| 2等 | 100,000,000円 | 23本 |
| 3等 | 10,000,000円 | 92本 |
| 4等 | 1,000,000円 | 920本 |
| 5等 | 10,000円 | 1,380,000本 |
| 6等 | 3,000円 | 4,600,000本 |
| 7等 | 300円 | 46,000,000本 |

※発売総額1,380億円・23ユニットの場合（1ユニット2,000万枚）

## セットアップ

### 前提条件

- **macOS**: 13.0以上
- **Swift**: 6.2以上
- **Xcode**: 16.0以上（Swift 6.0対応）

### ビルド

```bash
# Debugビルド（開発・デバッグ用）
swift build
```

## 実行・クライアント設定（Claude Desktop）

Claude DesktopのMCPサーバー設定ファイルに以下を追加します。

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "lottery-simulator": {
      "command": "LotteryMCPServerへのPath/.build/release/LotteryMCPServer"
    }
  }
}
```

> **注意**: パスは実際のプロジェクトの場所に合わせて変更してください。

設定後、**Claude Desktopを再起動**してください。

## 手動実行（開発・テスト）

```bash
# Debugビルドの実行
.build/debug/LotteryMCPServer

```

## 利用可能なツール

### `simulate_lottery`

年末ジャンボ宝くじのシミュレーションを実行します。

**パラメータ:**
- `tickets` (integer, 必須): 購入する宝くじの枚数（1以上）

**使用例（Claude Desktop）:**
```
10枚の宝くじを買ったらどうなるかシミュレーションして
```

**出力例:**
```
年末ジャンボ宝くじシミュレーション結果
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
購入枚数: 10枚
購入金額: ¥3,000

【当選結果】
7等: 2本 - ¥600

【収支】
総当選金額: ¥600
収支: -¥2,400
還元率: 20.00%
```

## 技術スタック

- **Swift**: 6.2+
- **Swift MCP SDK**: [modelcontextprotocol/swift-sdk](https://github.com/modelcontextprotocol/swift-sdk)
- **プラットフォーム**: macOS 13.0+

## ライセンス

MIT License
