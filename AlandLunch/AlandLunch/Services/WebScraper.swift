import Foundation
import WebKit

class WebScraper: NSObject, ObservableObject {
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<[Restaurant], Error>?

    private let lunchURL = URL(string: "https://www.aland.com/lunch")!

    override init() {
        super.init()
    }

    @MainActor
    func fetchRestaurants() async throws -> [Restaurant] {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let config = WKWebViewConfiguration()
            config.websiteDataStore = .nonPersistent()

            let webView = WKWebView(frame: .zero, configuration: config)
            webView.navigationDelegate = self
            self.webView = webView

            let request = URLRequest(url: lunchURL, cachePolicy: .reloadIgnoringLocalCacheData)
            webView.load(request)

            // Timeout after 30 seconds
            Task {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                if self.continuation != nil {
                    self.continuation?.resume(throwing: ScraperError.timeout)
                    self.continuation = nil
                    self.webView = nil
                }
            }
        }
    }

    private func parseHTML() {
        let script = """
        (function() {
            const restaurants = [];

            // Find all restaurant sections
            const restaurantElements = document.querySelectorAll('[class*="restaurant"], [class*="lunch"], article, .card, section');

            // Try to find restaurant blocks by looking for common patterns
            const allElements = document.body.innerHTML;

            // Look for specific patterns in the page
            const restaurantBlocks = document.querySelectorAll('div, section, article');

            restaurantBlocks.forEach((block) => {
                // Look for restaurant name (usually in h2, h3, or strong)
                const nameEl = block.querySelector('h1, h2, h3, h4, [class*="name"], [class*="title"]');
                const name = nameEl ? nameEl.textContent.trim() : null;

                if (!name || name.length < 2 || name.length > 100) return;

                // Look for phone number
                const phoneMatch = block.innerHTML.match(/\\+?\\d{1,4}[\\s-]?\\d{2,4}[\\s-]?\\d{4,}/);
                const phone = phoneMatch ? phoneMatch[0] : null;

                // Look for menu items (elements with price patterns like "X.XX€" or "X€")
                const priceRegex = /\\d+[.,]?\\d*\\s*€/g;
                const menuItems = [];

                const itemElements = block.querySelectorAll('div, p, li, tr');
                itemElements.forEach((item) => {
                    const text = item.textContent.trim();
                    const priceMatch = text.match(/\\d+[.,]?\\d*\\s*€/);

                    if (priceMatch && text.length > 5 && text.length < 500) {
                        const price = priceMatch[0];
                        const itemText = text.replace(price, '').trim();

                        // Try to split into category and description
                        const parts = itemText.split(/\\s{2,}|\\n/);
                        const category = parts[0] || '';
                        const description = parts.slice(1).join(' ').trim() || null;

                        if (category.length > 2) {
                            menuItems.push({
                                category: category,
                                name: category,
                                description: description,
                                price: price
                            });
                        }
                    }
                });

                if (menuItems.length > 0) {
                    // Check if we already have this restaurant
                    const exists = restaurants.some(r => r.name === name);
                    if (!exists) {
                        restaurants.push({
                            id: name.toLowerCase().replace(/[^a-z0-9]/g, '-'),
                            name: name,
                            phone: phone,
                            sections: [{
                                title: 'Lunch',
                                items: menuItems
                            }]
                        });
                    }
                }
            });

            return JSON.stringify(restaurants);
        })();
        """

        webView?.evaluateJavaScript(script) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.continuation?.resume(throwing: ScraperError.javascriptError(error.localizedDescription))
                self.continuation = nil
                self.webView = nil
                return
            }

            guard let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8) else {
                self.continuation?.resume(throwing: ScraperError.parsingError)
                self.continuation = nil
                self.webView = nil
                return
            }

            do {
                let decoded = try JSONDecoder().decode([ScrapedRestaurant].self, from: data)
                let restaurants = decoded.map { scraped in
                    Restaurant(
                        id: scraped.id,
                        name: scraped.name,
                        phone: scraped.phone,
                        imageURL: nil,
                        sections: scraped.sections.map { section in
                            MenuSection(
                                title: section.title,
                                items: section.items.map { item in
                                    MenuItem(
                                        category: item.category,
                                        name: item.name,
                                        description: item.description,
                                        price: item.price
                                    )
                                }
                            )
                        }
                    )
                }
                self.continuation?.resume(returning: restaurants)
            } catch {
                self.continuation?.resume(throwing: ScraperError.decodingError(error.localizedDescription))
            }

            self.continuation = nil
            self.webView = nil
        }
    }
}

// MARK: - WKNavigationDelegate

extension WebScraper: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Wait a bit for JavaScript to render content
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.parseHTML()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: ScraperError.networkError(error.localizedDescription))
        continuation = nil
        self.webView = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: ScraperError.networkError(error.localizedDescription))
        continuation = nil
        self.webView = nil
    }
}

// MARK: - Helper Types

private struct ScrapedRestaurant: Codable {
    let id: String
    let name: String
    let phone: String?
    let sections: [ScrapedSection]
}

private struct ScrapedSection: Codable {
    let title: String
    let items: [ScrapedItem]
}

private struct ScrapedItem: Codable {
    let category: String
    let name: String
    let description: String?
    let price: String
}

enum ScraperError: LocalizedError {
    case timeout
    case networkError(String)
    case javascriptError(String)
    case parsingError
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Request timed out. Please check your internet connection."
        case .networkError(let message):
            return "Network error: \(message)"
        case .javascriptError(let message):
            return "Failed to parse page: \(message)"
        case .parsingError:
            return "Failed to parse restaurant data"
        case .decodingError(let message):
            return "Failed to decode data: \(message)"
        }
    }
}
