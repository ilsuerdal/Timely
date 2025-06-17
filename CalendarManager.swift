import Foundation

class CalendarManager {
    static let shared = CalendarManager()

    private init() {}

    func createGoogleCalendarEvent(
        accessToken: String,
        title: String,
        description: String? = nil,
        startDate: Date,
        endDate: Date,
        timeZone: String = "Europe/Istanbul",
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: timeZone)

        var event: [String: Any] = [
            "summary": title,
            "start": [
                "dateTime": dateFormatter.string(from: startDate),
                "timeZone": timeZone
            ],
            "end": [
                "dateTime": dateFormatter.string(from: endDate),
                "timeZone": timeZone
            ]
        ]

        if let description = description {
            event["description"] = description
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: event, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "Invalid response", code: -1)))
                return
            }

            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                completion(.success(()))
            } else {
                let errorMsg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                completion(.failure(NSError(domain: errorMsg, code: httpResponse.statusCode)))
            }
        }.resume()
    }
}

