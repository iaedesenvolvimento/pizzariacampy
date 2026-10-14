from collections import defaultdict, deque
from time import monotonic


class InMemoryRateLimiter:
    def __init__(self, limit: int, window_seconds: int):
        self.limit = limit
        self.window_seconds = window_seconds
        self._requests: dict[str, deque[float]] = defaultdict(deque)

    def allow(self, key: str) -> tuple[bool, int]:
        now = monotonic()
        requests = self._requests[key]
        while requests and now - requests[0] >= self.window_seconds:
            requests.popleft()
        if len(requests) >= self.limit:
            retry_after = max(1, int(self.window_seconds - (now - requests[0])))
            return False, retry_after
        requests.append(now)
        return True, 0


auth_rate_limiter = InMemoryRateLimiter(limit=10, window_seconds=60)
