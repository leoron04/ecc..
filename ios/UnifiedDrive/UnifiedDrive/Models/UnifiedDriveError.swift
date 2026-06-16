import Foundation

enum UnifiedDriveError: LocalizedError {
    case invalidOnboardingCode
    case missingConfiguration
    case invalidResponse
    case httpStatus(Int)
    case xmlParsingFailed
    case unsupportedCachedFile
    case emptyName

    var errorDescription: String? {
        switch self {
        case .invalidOnboardingCode:
            return "Codice non valido. Usa il formato IP|password."
        case .missingConfiguration:
            return "Configurazione mancante."
        case .invalidResponse:
            return "Risposta del server non valida."
        case .httpStatus(let code):
            return "Il server ha risposto con errore HTTP \(code)."
        case .xmlParsingFailed:
            return "Impossibile leggere la risposta WebDAV."
        case .unsupportedCachedFile:
            return "File non disponibile nella cache."
        case .emptyName:
            return "Inserisci un nome valido."
        }
    }
}

