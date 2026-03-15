import Foundation
import XCTest

// MARK: - FixtureLoader
//
// CommBoardUITests/Fixtures/ 디렉토리의 JSON 파일을 로드합니다.
// Bundle(for:) 방식으로 테스트 번들에서 파일을 찾습니다.
//
// XcodeGen 빌드 시 CommBoardUITests 디렉토리의 모든 파일이
// 번들에 포함됩니다. JSON 파일은 번들 루트에서 검색됩니다.

enum FixtureLoader {

    // MARK: - Errors

    enum Error: LocalizedError {
        case fileNotFound(name: String, extension: String)
        case decodingFailed(name: String, underlyingError: Swift.Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name, let ext):
                return "Fixture 파일을 찾을 수 없습니다: \(name).\(ext)"
            case .decodingFailed(let name, let underlyingError):
                return "Fixture 파일 디코딩 실패: \(name) — \(underlyingError.localizedDescription)"
            }
        }
    }

    // MARK: - Raw Data

    /// 지정된 이름의 JSON fixture 파일을 Data로 반환합니다.
    ///
    /// 탐색 순서:
    /// 1. 번들 루트에서 직접 검색
    /// 2. 번들 내 Fixtures 서브디렉토리에서 검색
    static func data(
        fileName: String,
        fileExtension: String = "json",
        bundle: Bundle = Bundle(for: FixtureLoaderBundleToken.self)
    ) throws -> Data {
        // 1. 번들 루트에서 검색
        if let url = bundle.url(forResource: fileName, withExtension: fileExtension) {
            return try Data(contentsOf: url)
        }

        // 2. Fixtures 서브디렉토리에서 검색
        if let url = bundle.url(
            forResource: fileName,
            withExtension: fileExtension,
            subdirectory: "Fixtures"
        ) {
            return try Data(contentsOf: url)
        }

        throw Error.fileNotFound(name: fileName, extension: fileExtension)
    }

    // MARK: - Decoded

    /// 지정된 이름의 JSON fixture 파일을 Decodable 타입으로 디코딩하여 반환합니다.
    static func decode<T: Decodable>(
        _ type: T.Type,
        from fileName: String,
        fileExtension: String = "json",
        bundle: Bundle = Bundle(for: FixtureLoaderBundleToken.self),
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        let data = try FixtureLoader.data(
            fileName: fileName,
            fileExtension: fileExtension,
            bundle: bundle
        )
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw Error.decodingFailed(name: fileName, underlyingError: error)
        }
    }
}

// MARK: - FixtureLoaderBundleToken
//
// Bundle(for:)에 전달할 클래스. 이 클래스가 속한 번들이 곧
// CommBoardUITests 번들이 됩니다.

final class FixtureLoaderBundleToken {}
