import Foundation
import TSSSDK

class TssCallback: NSObject, TssCallbackProtocol {
    let completion: (Int32, String?) -> Void

    init(completion: @escaping (Int32, String?) -> Void) {
        self.completion = completion
    }

    func callback(_ code: Int32, message: String?) {
        completion(code, message)
    }
}

class TssCallbackWithData: NSObject, TssCallbackWithDataProtocol {
    let completion: (Int32, String?, String?) -> Void

    init(completion: @escaping (Int32, String?, String?) -> Void) {
        self.completion = completion
    }

    func callback(_ code: Int32, message: String?, data: String?) {
        completion(code, message, data)
    }
}

public class UCW: UCWPublic {
    var config: SDKConfig
    var connCode: ConnCode
    var connMessage: String?

    public init(config: SDKConfig, secretsFile: String, passphrase: String, connCallback: @escaping(ConnCode, String?) -> Void = { _, _ in }) throws {
        self.config = config
        self.connCode = ConnCode.CodeUnknown
        self.connMessage = nil
        try super.init(secretsFile: secretsFile)
        self.handler = nil
        try self.open(passphrase: passphrase, connCallback: connCallback)
    }

    deinit {
        print("UCW deinitialization")
    }

    private func open(passphrase: String, connCallback: @escaping(ConnCode, String?) -> Void = { _, _ in }) throws {
        guard self.handler == nil else {
            return
        }

        let tssSDKConfig = TssSDKConfig()
        tssSDKConfig.env = self.config.env.rawValue
        // tssSDKConfig.txVerifyURL = self.config.txVerifyURL
        tssSDKConfig.debug = self.config.debug

        guard let result = TssOpen(tssSDKConfig, self.secretsFile, passphrase, TssCallback { [weak self] code, message in
            self?.connCode = ConnCode(rawValue: Int32(code)) ?? .CodeUnknown
            self?.connMessage = message
            if let connCode = self?.connCode, let connMessage = self?.connMessage {
                connCallback(connCode, connMessage)
            }
        }) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to open secrets")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }
        do {
            let decoder = JSONDecoder()
            let handlerResult = try decoder.decode(HandlerResult.self, from: result.data.data(using: .utf8)!)
            self.handler = handlerResult.handler
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode result:\(error)")
        }
    }

    private func close() throws {
        guard let result = TssClose(self.handler) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to close secrets")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }
        self.handler = nil
        self.connCode = ConnCode.CodeUnknown
        self.connMessage = nil
    }

    public func getConnStatus() -> (ConnCode, String?) {
        return (self.connCode, self.connMessage)
    }

    public func listPendingTSSRequests() async throws -> [TSSRequest] {
        return try await withCheckedThrowingContinuation { continuation in
            TssListPendingTSSRequests(self.handler, self.config.timeout, TssCallbackWithData { code, message, data in
                if code != SDKErrorCode.success.rawValue {
                    continuation.resume(throwing: SDKError.apiError(code: code, message: message))
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to get result data"))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let tssRequestResult = try decoder.decode(TSSRequestResult.self, from: data.data(using: .utf8)!)
                    if let results = tssRequestResult.data {
                         continuation.resume(returning: results)
                    } else {
                         continuation.resume(returning: [])
                    }
                } catch {
                    continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode TSS requests in result:\(error)"))
                }

            })
        }
    }

    public func getTSSRequests(tssRequestIDs: [String]) async throws -> [TSSRequest] {
        return try await withCheckedThrowingContinuation { continuation in
            let jsonData: Data
            do {
                jsonData = try JSONSerialization.data(withJSONObject: tssRequestIDs, options: [])
            } catch {
                continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert tssRequestIDs to JSON string:\(error)"))
                return
            }

            guard let jsonTSSRequestIDs = String(data: jsonData, encoding: .utf8) else {
                continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert tssRequestIDs to JSON string"))
                return
            }

            TssGetTSSRequests(self.handler, jsonTSSRequestIDs, self.config.timeout, TssCallbackWithData { code, message, data in
                if code != SDKErrorCode.success.rawValue {
                    continuation.resume(throwing: SDKError.apiError(code: code, message: message))
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to get result data"))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let tssRequestResult = try decoder.decode(TSSRequestResult.self, from: data.data(using: .utf8)!)
                    if let results = tssRequestResult.data {
                        continuation.resume(returning: results)
                    } else {
                        continuation.resume(returning: [])
                    }
                } catch {
                    continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode TSS requests in result:\(error)"))
                }
            })
        }
    }

    public func approveTSSRequests(tssRequestIDs: [String]) throws {
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: tssRequestIDs, options: [])
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert tssRequestIDs to JSON string:\(error)")
        }

        guard let jsonTSSRequestIDs = String(data: jsonData, encoding: .utf8) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert tssRequestIDs to JSON string")
        }

        guard let result = TssApproveTSSRequests(self.handler, jsonTSSRequestIDs) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to approve TSS requests")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }
    }

    public func rejectTSSRequests(tssRequestIDs: [String], reason: String) throws {
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: tssRequestIDs, options: [])
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert tssRequestIDs to JSON string:\(error)")
        }

        guard let jsonTSSRequestIDs = String(data: jsonData, encoding: .utf8) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert tssRequestIDs to JSON string")
        }

        guard let result = TssRejectTSSRequests(self.handler, jsonTSSRequestIDs, reason) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to reject TSS requests")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }
    }

    public func listPendingTransactions() async throws -> [Transaction] {
        return try await withCheckedThrowingContinuation { continuation in
            TssListPendingTransactions(self.handler, self.config.timeout, TssCallbackWithData { code, message, data in
                if code != SDKErrorCode.success.rawValue {
                    continuation.resume(throwing: SDKError.apiError(code: code, message: message))
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to get result data"))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let transactionResult = try decoder.decode(TransactionResult.self, from: data.data(using: .utf8)!)
                    if let results = transactionResult.data {
                         continuation.resume(returning: results)
                    } else {
                         continuation.resume(returning: [])
                    }
                } catch {
                    continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode transactions in result:\(error)"))
                }
            })
        }
    }

    public func getTransactions(transactionIDs: [String]) async throws -> [Transaction] {
        return try await withCheckedThrowingContinuation { continuation in
            let jsonData: Data
            do {
                jsonData = try JSONSerialization.data(withJSONObject: transactionIDs, options: [])
            } catch {
                continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert transactionIDs to JSON string:\(error)"))
                return
            }

            guard let jsonTransactionIDs = String(data: jsonData, encoding: .utf8) else {
                continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert transactionIDs to JSON string"))
                return
            }

            TssGetTransactions(self.handler, jsonTransactionIDs, self.config.timeout, TssCallbackWithData { code, message, data in
                if code != SDKErrorCode.success.rawValue {
                    continuation.resume(throwing: SDKError.apiError(code: code, message: message))
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to get result data"))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let transactionResult = try decoder.decode(TransactionResult.self, from: data.data(using: .utf8)!)
                    if let results = transactionResult.data {
                         continuation.resume(returning: results)
                    } else {
                         continuation.resume(returning: [])
                    }
                } catch {
                    continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode transaction in result:\(error)"))
                }
            })
        }
    }

    public func approveTransactions(transactionIDs: [String]) throws {
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: transactionIDs, options: [])
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert transactionIDs to JSON string:\(error)")
        }

        guard let jsonTransactionIDs = String(data: jsonData, encoding: .utf8) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert transactionIDs to JSON string")
        }

        guard let result = TssApproveTransactions(self.handler, jsonTransactionIDs) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to approve transactions")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }
    }

    public func rejectTransactions(transactionIDs: [String], reason: String) throws {
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: transactionIDs, options: [])
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert transactionIDs to JSON string:\(error)")
        }

        guard let jsonTransactionIDs = String(data: jsonData, encoding: .utf8) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert transactionIDs to JSON string")
        }

        guard let result = TssRejectTransactions(self.handler, jsonTransactionIDs, reason) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to reject transactions")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }
    }

    public func exportSecrets(exportPassphrase: String) throws -> String {
        guard let result = TssExportSecrets(self.handler, exportPassphrase) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to export secrets")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(SecretsResult.self, from: result.data.data(using: .utf8)!)
            return result.data
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode secrets result in result:\(error)")
        }
    }

    public func exportRecoveryKeyShares(tssKeyShareGroupIDs: [String], exportPassphrase: String) throws -> String {
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: tssKeyShareGroupIDs, options: [])
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert groupIDs to JSON string:\(error)")
        }

        guard let jsonGroupIDs = String(data: jsonData, encoding: .utf8) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert groupIDs to JSON string")
        }

        guard let result = TssExportRecoveryKeyShares(self.handler, jsonGroupIDs, exportPassphrase) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to export key shares")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(SecretsResult.self, from: result.data.data(using: .utf8)!)
            return result.data
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode secrets result in result:\(error)")
        }
    }

//
//    public func SignWithKeyShare(tssKeyShareGroupID: String, nonce: String, message: String) throws -> String {
//        guard let result = TssKeyShareSign(self.handler, groupID, nonce, message) else {
//            throw SdkError.commonError(code: SDKErrorCode.commonError, message: "Failed to key share sign")
//        }
//
//        guard result.code == SdkErrorCode.success.rawValue else {
//            throw SdkError.apiError(code: result.code, message: result.message)
//        }
//
//        do {
//            let decoder = JSONDecoder()
//            let shareSignResult = try decoder.decode(ShareSignResult.self, from: result.data.data(using: .utf8)!)
//            return shareSignResult.signature
//        } catch {
//            throw SdkError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode result:\(error)")
//        }
//    }
}

public class UCWPublic {
    var handler: String?
    var secretsFile: String

    public init(secretsFile: String) throws {
        self.secretsFile = secretsFile
        self.handler = nil
        try self.openPublic()
    }

    deinit {
        print("UCWPublic deinitialization")
        do {
            try self.close()
        } catch {
            print("Error during UCWPublic deinitialization: \(error)")
        }
    }

    private func openPublic() throws {
        guard self.handler == nil else {
            return
        }

        guard let result = TssOpenPublic(self.secretsFile) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to open database")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }

        do {
            let decoder = JSONDecoder()
            let handlerResult = try decoder.decode(HandlerResult.self, from: result.data.data(using: .utf8)!)
            self.handler = handlerResult.handler
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode result:\(error)")
        }
    }

    private func close() throws {
        guard let result = TssClose(self.handler) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to close database")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }
        self.handler = nil
    }

    public func getTSSNodeID() throws -> String {
        guard let result = TssGetTSSNodeID(self.handler) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to get node info")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }

        do {
            let decoder = JSONDecoder()
            let nodeResult = try decoder.decode(NodeResult.self, from: result.data.data(using: .utf8)!)
            return nodeResult.tssNodeID
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode result:\(error)")
        }
    }

    public func getTSSKeyShareGroups(tssKeyShareGroupIDs: [String]) throws -> [TSSKeyShareGroup] {
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: tssKeyShareGroupIDs, options: [])
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert groupIDs to JSON string:\(error)")
        }

        guard let jsonGroupIDs = String(data: jsonData, encoding: .utf8) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert groupIDs to JSON string")
        }

        guard let result = TssGetTSSKeyShareGroups(self.handler, jsonGroupIDs) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to get group info")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }

        do {
            let decoder = JSONDecoder()
            let groupResult = try decoder.decode(GroupResult.self, from: result.data.data(using: .utf8)!)
            if let results = groupResult.data {
                return results
            } else {
                return []
            }
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode group info in result:\(error)")
        }
    }

    public func listTSSKeyShareGroups()  throws -> [TSSKeyShareGroup] {
        guard let result = TssListTSSKeyShareGroups(self.handler) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to get all group info")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }

        do {
            let decoder = JSONDecoder()
            let groupResult = try decoder.decode(GroupResult.self, from: result.data.data(using: .utf8)!)
            if let results = groupResult.data {
                return results
            } else {
                return []
            }
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode group information in result:\(error)")
        }
    }
}


public class UCWRecoverKey {
    var tssKeyShareGroupID: String

    public init(tssKeyShareGroupID: String) {
        self.tssKeyShareGroupID = tssKeyShareGroupID
    }

    deinit {
        print("UCWRecoverKey deinitialization")
        self.cleanRecoveryKeyShares()
    }

    private func cleanRecoveryKeyShares() {
        TssCleanRecoveryKeyShares()
        self.tssKeyShareGroupID = ""
    }

    public func importRecoveryKeyShare(jsonRecoverySecrets: String, exportPassphrase: String) throws {
        guard let result = TssImportRecoveryKeyShare(self.tssKeyShareGroupID, jsonRecoverySecrets, exportPassphrase) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to add recovery key shares")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }
    }

    public func recoverPrivateKeys(addressInfos: [AddressInfo]) throws -> [PrivateKeyInfo] {
        let jsonData: Data
        do {
            let encoder = JSONEncoder()
            jsonData = try encoder.encode(addressInfos)
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert addressInfos to JSON string:\(error)")
        }

        guard let jsonAddressInfos = String(data: jsonData, encoding: .utf8) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to convert addressInfos to JSON string")
        }

        guard let result = TssRecoverPrivateKeys(self.tssKeyShareGroupID, jsonAddressInfos) else {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to recover private keys")
        }

        guard result.code == SDKErrorCode.success.rawValue else {
            throw SDKError.apiError(code: result.code, message: result.message)
        }

        do {
            let decoder = JSONDecoder()
            let recoverResult = try decoder.decode(RecoverResult.self, from: result.data.data(using: .utf8)!)
            if let results = recoverResult.data {
                return results
            } else {
                return []
            }
        } catch {
            throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode recovery keys in result:\(error)")
        }
    }
}

public func getSDKInfo() throws -> SDKInfo {
    guard let result = TssGetSDKInfo() else {
        throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to get SDK info")
    }

    guard result.code == SDKErrorCode.success.rawValue else {
        throw SDKError.apiError(code: result.code, message: result.message)
    }

    do {
        let decoder = JSONDecoder()
        let sdkInfo = try decoder.decode(SDKInfo.self, from: result.data.data(using: .utf8)!)
        return sdkInfo
    } catch {
        throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode result:\(error)")
    }
}


public func initializeSecrets(secretsFile: String, passphrase: String) async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
        TssInitializeSecrets(secretsFile, passphrase, TssCallbackWithData { code, message, data in
            if code != SDKErrorCode.success.rawValue {
                continuation.resume(throwing: SDKError.apiError(code: code, message: message))
                return
            }

            guard let data = data else {
                continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to get result data"))
                return
            }

            do {
                let decoder = JSONDecoder()
                let nodeResult = try decoder.decode(NodeResult.self, from: data.data(using: .utf8)!)
                continuation.resume(returning: (nodeResult.tssNodeID))
            } catch {
                continuation.resume(throwing: SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode node information in result:\(error)"))
            }
        })
    }
}


public func importSecrets(jsonRecoverySecrets: String, exportPassphrase: String, newSecretsFile: String, newPassphrase: String) throws -> String {
    guard let result = TssImportSecrets(jsonRecoverySecrets, exportPassphrase, newSecretsFile, newPassphrase) else {
        throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to import secrets")
    }

    guard result.code == SDKErrorCode.success.rawValue else {
        throw SDKError.apiError(code: result.code, message: result.message)
    }

    do {
        let decoder = JSONDecoder()
        let nodeResult = try decoder.decode(NodeResult.self, from: result.data.data(using: .utf8)!)
        return nodeResult.tssNodeID
    } catch {
        throw SDKError.commonError(code: SDKErrorCode.commonError, message: "Failed to decode result:\(error)")
    }
}

class TssLogger: NSObject, TssLoggerProtocol {
    let completion: (String?, String?) -> Void

    init(completion: @escaping (String?, String?) -> Void) {
        self.completion = completion
    }

    func log(_ level: String?, message: String?) {
        completion(level, message)
    }
}

public func setLogger(completion: @escaping (String?, String?) -> Void) {
    let logger = TssLogger(completion: completion)
    TssSetLogger(logger)
}
