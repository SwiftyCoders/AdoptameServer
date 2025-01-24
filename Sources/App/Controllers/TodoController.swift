import Fluent
import Vapor

struct TodoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("todos")

        todos.get(use: self.index)
        todos.post(use: self.create)
        todos.group(":todoID") { todo in
            todo.delete(use: self.delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [String] {
        []
    }

    @Sendable
    func create(req: Request) async throws -> String {
        return ""
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {        
        .ok
    }
}
