import Foundation

public enum SDKError: Error {
    case commonError(code : SDKErrorCode, message: String)
    case apiError(code : Int32, message: String?)
}

public enum SDKErrorCode: Int32 {
    case success = 0
    case commonError = 9000

    var description: String {
        switch self {
        case .success:
            return "Success"
        case .commonError:
            return "Common Error"
        }
    }
}

public enum Status: Int32, Codable {
    case unknown = 100
    case scheduling = 110
    case initializing = 120
    case approving = 130
    case processing = 140
    case declined = 160
    case failed = 170
    case canceled = 180
    case completed = 190
}

public enum GroupType: Int32, Codable {
    case ecdsaTSS = 1
    case eddsaTSS = 2
}

public enum ConnCode: Int32 {
    case unknown = 0

    case connected = 1300
    case disconnected = 1301
    case connectClose = 1302

    case connectError = 1310
    case connectURLParseError = 1311

    case connectRefused = 1320
    case connectFail = 1321

    case connectProxyError = 1350
    case connectProxyParseError = 1351
}

public struct SDKConfig {
    public let env: Env
    public let timeout: Int32
    public let debug: Bool

    public init(env: Env, timeout: Int32, debug: Bool) {
        self.env = env
        self.timeout = timeout
        self.debug = debug
    }
}

public enum Env: String {
    case development = "development"
    case production = "production"
    case local = "local"
}

public struct AddressInfo: Codable {
    public let bip32Path: String
    public let pubKey: String

    public init(bip32Path: String, pubKey: String) {
        self.bip32Path = bip32Path
        self.pubKey = pubKey
    }
}

struct SecretsResult: Codable {
    let data: String

    enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}

struct HandlerResult: Codable {
    let handler: String

    enum CodingKeys: String, CodingKey {
        case handler = "handler"
    }
}

struct NodeResult: Codable {
    let tssNodeID: String

    enum CodingKeys: String, CodingKey {
        case tssNodeID = "tss_node_id"
    }
}

public struct SDKInfo: Codable {
    public let version: String

    enum CodingKeys: String, CodingKey {
        case version = "version"
    }
}

struct RecoverResult: Codable {
    let data: [PrivateKeyInfo]?

    enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}

public struct PrivateKeyInfo: Codable {
    public let bip32Path: String
    public let publicKey: String
    public let privateKey: PrivateKey?

    enum CodingKeys: String, CodingKey {
        case bip32Path = "bip32_path"
        case publicKey = "extended_public_key"
        case privateKey = "private_key"
    }
}

public struct PrivateKey: Codable {
    public let extPrivateKey: String
    public let hexPrivateKey: String

    enum CodingKeys: String, CodingKey {
        case extPrivateKey = "extended_private_key"
        case hexPrivateKey = "hex_private_key"
    }
}

struct ShareSignResult: Codable {
    let signature: String

    enum CodingKeys: String, CodingKey {
        case signature = "signature"
    }
}

struct GroupResult: Codable {
    let data: [TSSKeyShareGroup]?

    enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}

public struct TSSKeyShareGroup: Codable {
    public let tssKeyShareGroupID: String
    // public let canonicalGroupID: String
    // public let protocolGroupID: String
    // public let protocolType: String
    public let createdTimeStamp: Int64
    public let type: GroupType
    public let rootPubKey: String
    public let chainCode: String
    public let curve: String
    public let threshold: Int32
    public let participants: [SharePublicData]?

    enum CodingKeys: String, CodingKey {
        case tssKeyShareGroupID = "id"
        // case canonicalGroupID = "canonical_group_id"
        // case protocolGroupID = "protocol_group_id"
        // case protocolType = "protocol_type"
        case createdTimeStamp = "created_timestamp"
        case type = "type"
        case rootPubKey = "root_extended_public_key"
        case chainCode = "chaincode"
        case curve = "curve"
        case threshold = "threshold"
        case participants = "participants"
     }
}

public struct SharePublicData: Codable {
    public let tssNodeID: String
    public let shareID: String
    public let sharePubKey: String

    enum CodingKeys: String, CodingKey {
        case tssNodeID = "node_id"
        case shareID = "share_id"
        case sharePubKey = "share_public_key"
   }
}

struct TSSRequestResult: Codable {
    let data: [TSSRequest]?

    enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}

public struct TSSRequest: Codable {
    public let tssRequestID: String
    public let status: Status

    // org
    // project
    // vault
    // sourceKeyShareHolderGroup
    // targetKeyShareHolderGroup
    // tssRequest

    public let results: [TSSKeyShareGroup]?
    public let failedReasons: [String]?

    enum CodingKeys: String, CodingKey {
        case tssRequestID = "tss_request_id"
        case status = "status"
        case results = "results"
        case failedReasons = "failed_reasons"
    }
}

struct TransactionResult: Codable {
    let data: [Transaction]?

    enum CodingKeys: String, CodingKey {
          case data = "data"
      }
}

public struct Transaction: Codable {
    public let transactionID: String
    public let status: Status

    // org
    // project
    // vault
    // wallet
    // signerKeyShareHolderGroup
    // transaction

    public let signDetails: [SignDetail]?
    public let results: [Signatures]?
    public let failedReasons: [String]?

    enum CodingKeys: String, CodingKey {
        case transactionID = "transaction_id"
        case status = "status"
        case signDetails = "sign_details"
        case results = "results"
        case failedReasons = "failed_reasons"
     }
}

public struct SignDetail: Codable {
    public let signatureType: Int32
    public let tssProtocol: Int32
    public let bip32PathList: [String]?
    public let msgHashList: [String]?
    public let tweakList: [String]?

    enum CodingKeys: String, CodingKey {
        case signatureType = "signature_type"
        case tssProtocol = "tss_protocol"
        case bip32PathList = "bip32_path_list"
        case msgHashList = "msg_hash_list"
        case tweakList = "tweak_list"
    }
}

public struct Signatures: Codable {
    public let signatures: [Signature]?
    public let signatureType: Int32?
    public let tssProtocol: Int32?

    enum CodingKeys: String, CodingKey {
        case signatures = "signatures"
        case signatureType = "signature_type"
        case tssProtocol = "tss_protocol"
    }
}

public struct Signature: Codable {
    public let bip32Path: String
    public let msgHash: String
    public let tweak: String?
    public let signature: String?
    public let signatureRecovery: String?

    enum CodingKeys: String, CodingKey {
        case bip32Path = "bip32_path"
        case msgHash = "msg_hash"
        case tweak = "tweak"
        case signature = "signature"
        case signatureRecovery = "signature_recovery"
    }
}
