import Foundation
import BigInt

struct SwapValues: Decodable {
    var dexId: UInt32?
    let amount: String
    let fee: String
    let rewards: [String]

    enum CodingKeys: String, CodingKey {
        case amount
        case fee
        case rewards
    }
}

struct SubstrateSwapValues: Decodable {
    var dexId: UInt32?
    let amount: BigUInt
    let fee: BigUInt
    let rewards: [String]
}
