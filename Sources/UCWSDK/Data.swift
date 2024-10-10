import Foundation

enum SDKError: Error {
    case commonError(code : SDKErrorCode, message: String)
    case apiError(code : Int32, message: String?)
}

enum SDKErrorCode: Int32 {
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

enum Status: Int32, Codable {
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

enum NodeType: Int32, Codable {
    case coboCoSigner = 20
    case mobileCoSigner = 30
    case apiCoSigner = 31
}

enum GroupType: Int32, Codable {
    case ecdsaTSS = 1
    case eddsaTSS = 2
}

enum ConnCode: Int32 {
    case CodeUnknown = 0

    case CodeConnected = 1300
    case CodeDisconnected = 1301
    case CodeConnectClose = 1302

    case CodeConnectError = 1310
    case CodeConnectURLParseError = 1311

    case CodeConnectRefused = 1320
    case CodeConnectFail = 1321

    case CodeConnectProxyError = 1350
    case CodeConnectProxyParseError = 1351
}

struct SDKConfig {
    let env: Env
    // let txVerifyURL: String
    let timeout: Int32
    let debug: Bool
}

enum Env: String {
    case development = "development"
    case production = "production"
    case local = "local"
}

struct AddressInfo: Codable {
    let bip32Path: String
    let pubKey: String

    enum CodingKeys: String, CodingKey {
        case bip32Path = "bip32_path"
        case pubKey = "extended_public_key"
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

struct SDKInfo: Codable {
    let version: String

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

struct PrivateKeyInfo: Codable {
    let bip32Path: String
    let publicKey: String
    let privateKey: PrivateKey?

    enum CodingKeys: String, CodingKey {
        case bip32Path = "bip32_path"
        case publicKey = "extended_public_key"
        case privateKey = "private_key"
    }
}

struct PrivateKey: Codable {
    let extPrivateKey: String
    let hexPrivateKey: String

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

struct TSSKeyShareGroup: Codable {
    let tssKeyShareGroupID: String
    // let canonicalGroupID: String
    // let protocolGroupID: String
    // let protocolType: String
    let createdTime: String
    let type: GroupType
    let rootPubKey: String
    let chainCode: String
    let curve: String
    let threshold: Int32
    let participants: [SharePublicData]?

    enum CodingKeys: String, CodingKey {
        case tssKeyShareGroupID = "id"
        // case canonicalGroupID = "canonical_group_id"
        // case protocolGroupID = "protocol_group_id"
        // case protocolType = "protocol_type"
        case createdTime = "created_time"
        case type = "type"
        case rootPubKey = "root_extended_public_key"
        case chainCode = "chaincode"
        case curve = "curve"
        case threshold = "threshold"
        case participants = "participants"
     }
}

struct SharePublicData: Codable {
    let tssNodeID: String
    let shareID: String
    let sharePubKey: String

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

struct TSSRequest: Codable {
    let tssRequestID: String
    let status: Status

    // org
    // project
    // vault
    // sourceKeyShareHolderGroup
    // targetKeyShareHolderGroup
    // tssRequest

    let results: [TSSKeyShareGroup]?
    let failedReasons: [String]?

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

struct Transaction: Codable {
    let transactionID: String
    let status: Status

    // org
    // project
    // vault
    // wallet
    // signerKeyShareHolderGroup
    // transaction

    let signDetails: [SignDetail]?
    let results: [Signatures]?
    let failedReasons: [String]?

    enum CodingKeys: String, CodingKey {
        case transactionID = "transaction_id"
        case status = "status"
        case signDetails = "sign_details"
        case results = "results"
        case failedReasons = "failed_reasons"
     }
}

struct SignDetail: Codable {
    var signatureType: Int32
    var tssProtocol: Int32
    var bip32PathList: [String]?
    var msgHashList: [String]?
    var tweakList: [String]?

    enum CodingKeys: String, CodingKey {
        case signatureType = "signature_type"
        case tssProtocol = "tss_protocol"
        case bip32PathList = "bip32_path_list"
        case msgHashList = "msg_hash_list"
        case tweakList = "tweak_list"
    }
}

struct Signatures: Codable {
    var signatures: [Signature]?
    var signatureType: Int32?
    var tssProtocol: Int32?

    enum CodingKeys: String, CodingKey {
        case signatures = "signatures"
        case signatureType = "signature_type"
        case tssProtocol = "tss_protocol"
    }
}

struct Signature: Codable {
    let bip32Path: String
    let msgHash: String
    var tweak: String?
    let signature: String?
    let signatureRecovery: String?

    enum CodingKeys: String, CodingKey {
        case bip32Path = "bip32_path"
        case msgHash = "msg_hash"
        case tweak = "tweak"
        case signature = "signature"
        case signatureRecovery = "signature_recovery"
    }
}
