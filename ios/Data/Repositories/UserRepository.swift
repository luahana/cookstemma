import Foundation

final class UserRepository: UserRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getMyProfile() async -> RepositoryResult<MyProfile> {
        do {
            return .success(try await apiClient.request(UserEndpoint.myProfile))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getUserProfile(id: String) async -> RepositoryResult<UserProfile> {
        do {
            return .success(try await apiClient.request(UserEndpoint.profile(id: id)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func updateProfile(_ request: UpdateProfileRequest) async -> RepositoryResult<MyProfile> {
        do {
            return .success(try await apiClient.request(UserEndpoint.updateProfile(request)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func checkUsernameAvailability(_ username: String) async -> RepositoryResult<Bool> {
        do {
            let response: UsernameAvailabilityResponse = try await apiClient.request(UserEndpoint.checkUsername(username))
            return .success(response.available)
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getUserRecipes(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        do {
            return .success(try await apiClient.request(UserEndpoint.userRecipes(userId: userId, cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func follow(userId: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(UserEndpoint.follow(userId: userId))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func unfollow(userId: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(UserEndpoint.unfollow(userId: userId))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getFollowers(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>> {
        do {
            return .success(try await apiClient.request(UserEndpoint.followers(userId: userId, cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getFollowing(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>> {
        do {
            return .success(try await apiClient.request(UserEndpoint.following(userId: userId, cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func blockUser(userId: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(UserEndpoint.block(userId: userId))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func unblockUser(userId: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(UserEndpoint.unblock(userId: userId))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func reportUser(userId: String, reason: ReportReason) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(UserEndpoint.report(userId: userId, reason: reason))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    private func mapError(_ error: APIError) -> RepositoryError {
        switch error {
        case .networkError(let msg): return .networkError(msg)
        case .unauthorized: return .unauthorized
        case .notFound: return .notFound
        case .serverError(_, let msg): return .serverError(msg)
        case .decodingError(let msg): return .decodingError(msg)
        default: return .unknown
        }
    }
}
