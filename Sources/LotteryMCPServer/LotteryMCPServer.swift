import Foundation
import MCP

struct PrizeTier: Codable {
    let name: String
    let prize: Int
    let count: Int
    let probability: Double
}

struct LotteryResult: Codable {
    let tier: String
    let wins: Int
    let totalPrize: Int
}

struct SimulationResult: Codable {
    let ticketsPurchased: Int
    let totalCost: Int
    let results: [LotteryResult]
    let totalWinnings: Int
    let netProfit: Int
    let returnRate: Double
}

actor LotterySimulator {
    private let ticketPrice = 300
    private let ticketsPerUnit = 20_000_000

    private var prizeTiers: [PrizeTier]

    init() {
        let totalTickets = Double(ticketsPerUnit * 23)
        self.prizeTiers = [
            PrizeTier(name: "1等", prize: 700_000_000, count: 23, probability: Double(23) / totalTickets),
            PrizeTier(name: "1等前後賞", prize: 150_000_000, count: 46, probability: Double(46) / totalTickets),
            PrizeTier(name: "1等組違い賞", prize: 100_000, count: 4_577, probability: Double(4_577) / totalTickets),
            PrizeTier(name: "2等", prize: 100_000_000, count: 23, probability: Double(23) / totalTickets),
            PrizeTier(name: "3等", prize: 10_000_000, count: 92, probability: Double(92) / totalTickets),
            PrizeTier(name: "4等", prize: 1_000_000, count: 920, probability: Double(920) / totalTickets),
            PrizeTier(name: "5等", prize: 10_000, count: 1_380_000, probability: Double(1_380_000) / totalTickets),
            PrizeTier(name: "6等", prize: 3_000, count: 4_600_000, probability: Double(4_600_000) / totalTickets),
            PrizeTier(name: "7等", prize: 300, count: 46_000_000, probability: Double(46_000_000) / totalTickets)
        ]
    }

    func simulate(tickets: Int) -> SimulationResult {
        var wins: [String: Int] = [:]

        for tier in prizeTiers {
            wins[tier.name] = 0
        }

        for _ in 0..<tickets {
            let random = Double.random(in: 0..<1)
            var cumulativeProbability = 0.0

            for tier in prizeTiers {
                cumulativeProbability += tier.probability
                if random < cumulativeProbability {
                    wins[tier.name, default: 0] += 1
                    break
                }
            }
        }

        var results: [LotteryResult] = []
        var totalWinnings = 0

        for tier in prizeTiers {
            let tierWins = wins[tier.name] ?? 0
            if tierWins > 0 {
                let tierTotal = tierWins * tier.prize
                totalWinnings += tierTotal
                results.append(LotteryResult(
                    tier: tier.name,
                    wins: tierWins,
                    totalPrize: tierTotal
                ))
            }
        }

        let totalCost = tickets * ticketPrice
        let netProfit = totalWinnings - totalCost
        let returnRate = totalCost > 0 ? (Double(totalWinnings) / Double(totalCost)) * 100 : 0

        return SimulationResult(
            ticketsPurchased: tickets,
            totalCost: totalCost,
            results: results,
            totalWinnings: totalWinnings,
            netProfit: netProfit,
            returnRate: returnRate
        )
    }
}

@main
struct LotteryMCPServer {
    static func main() async throws {
        let simulator = LotterySimulator()

        let server = Server(
            name: "lottery-simulator",
            version: "1.0.0",
            capabilities: Server.Capabilities(
                tools: Server.Capabilities.Tools()
            )
        )

        // Register tools/list handler
        await server.withMethodHandler(ListTools.self) { _ in
            let tool = Tool(
                name: "simulate_lottery",
                description: "年末ジャンボ宝くじのシミュレーションを実行します。指定した枚数の宝くじを購入した場合の当選結果と収支を返します。",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "tickets": [
                            "type": "integer",
                            "description": "購入する宝くじの枚数",
                            "minimum": 1
                        ]
                    ],
                    "required": ["tickets"]
                ]
            )

            return ListTools.Result(tools: [tool])
        }

        // Register tools/call handler
        await server.withMethodHandler(CallTool.self) { params in
            guard params.name == "simulate_lottery" else {
                throw MCPError.invalidRequest("Unknown tool: \(params.name)")
            }

            guard let arguments = params.arguments else {
                throw MCPError.invalidParams("Missing arguments")
            }

            guard let ticketsValue = arguments["tickets"] else {
                throw MCPError.invalidParams("Missing tickets parameter")
            }

            let tickets: Int
            if let intValue = ticketsValue.intValue {
                tickets = intValue
            } else if let doubleValue = ticketsValue.doubleValue {
                tickets = Int(doubleValue)
            } else {
                throw MCPError.invalidParams("tickets parameter must be a number")
            }

            guard tickets > 0 else {
                throw MCPError.invalidParams("tickets must be greater than 0")
            }

            let result = await simulator.simulate(tickets: tickets)

            var output = """
            年末ジャンボ宝くじシミュレーション結果
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            購入枚数: \(result.ticketsPurchased)枚
            購入金額: ¥\(formatNumber(result.totalCost))

            【当選結果】
            """

            if result.results.isEmpty {
                output += "\n残念ながら当選はありませんでした"
            } else {
                for lotteryResult in result.results {
                    output += "\n\(lotteryResult.tier): \(lotteryResult.wins)本 - ¥\(formatNumber(lotteryResult.totalPrize))"
                }
            }

            output += """


            【収支】
            総当選金額: ¥\(formatNumber(result.totalWinnings))
            収支: \(result.netProfit >= 0 ? "+" : "")¥\(formatNumber(result.netProfit))
            還元率: \(String(format: "%.2f", result.returnRate))%
            """

            return CallTool.Result(
                content: [.text(output)]
            )
        }

        try await server.start(transport: StdioTransport())
        await server.waitUntilCompleted()
    }

    static func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
