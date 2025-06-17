import Foundation

// Calendar Event modeli
struct CalendarEvent {
    let id: String
    let summary: String
    let start: Date?
    let end: Date?
    let description: String?
}

class GoogleCalendarService {
    private let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func fetchEvents(completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
        let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let eventItems = json?["items"] as? [[String: Any]] ?? []
                
                let events: [CalendarEvent] = eventItems.compactMap { item in
                    guard let id = item["id"] as? String,
                          let summary = item["summary"] as? String else {
                        return nil
                    }
                    
                    let description = item["description"] as? String
                    
                    // Tarih parsing
                    let dateFormatter = ISO8601DateFormatter()
                    var startDate: Date?
                    var endDate: Date?
                    
                    if let startDict = item["start"] as? [String: Any],
                       let startString = startDict["dateTime"] as? String {
                        startDate = dateFormatter.date(from: startString)
                    }
                    
                    if let endDict = item["end"] as? [String: Any],
                       let endString = endDict["dateTime"] as? String {
                        endDate = dateFormatter.date(from: endString)
                    }
                    
                    return CalendarEvent(
                        id: id,
                        summary: summary,
                        start: startDate,
                        end: endDate,
                        description: description
                    )
                }
                
                completion(.success(events))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Yeni event oluşturma
    func createEvent(
        summary: String,
        description: String?,
        startTime: Date,
        endTime: Date,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let dateFormatter = ISO8601DateFormatter()
        
        let eventData: [String: Any] = [
            "summary": summary,
            "description": description ?? "",
            "start": [
                "dateTime": dateFormatter.string(from: startTime),
                "timeZone": TimeZone.current.identifier
            ],
            "end": [
                "dateTime": dateFormatter.string(from: endTime),
                "timeZone": TimeZone.current.identifier
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: eventData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let eventId = json["id"] as? String else {
                completion(.failure(NSError(domain: "CreateEventFailed", code: -1)))
                return
            }
            
            completion(.success(eventId))
        }.resume()
    }
}
