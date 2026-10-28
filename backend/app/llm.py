"""LLM 호출 모듈. .env의 LLM_PROVIDER로 어떤 서비스를 쓸지 고릅니다.

- mock      : API 키 없이 개발용 예시 응답 (기본값, 비용 0원)
- anthropic : Claude API   (LLM_API_KEY 필요)
- openai    : OpenAI API   (LLM_API_KEY, LLM_MODEL 필요)
- ollama    : 로컬/교내 서버의 Ollama (OLLAMA_URL, LLM_MODEL)
"""
import httpx

from app.config import settings


class LLMError(Exception):
    pass


DEFAULT_MODELS = {
    "anthropic": "claude-haiku-5-5",
    "openai": "",  # OpenAI는 사용할 모델명을 .env의 LLM_MODEL에 직접 적어주세요
    "ollama": "qwen2.5:7b-instruct",
}


def _model() -> str:
    return settings.LLM_MODEL or DEFAULT_MODELS.get(settings.LLM_PROVIDER, "")


def generate(system: str, prompt: str, max_tokens: int = 800) -> str:
    provider = settings.LLM_PROVIDER.lower()
    if provider == "mock":
        return _mock(prompt)
    if provider in ("anthropic", "openai") and not settings.LLM_API_KEY:
        raise LLMError(".env에 LLM_API_KEY가 없습니다.")
    if not _model():
        raise LLMError(".env에 LLM_MODEL을 지정해주세요.")
    try:
        with httpx.Client(timeout=settings.LLM_TIMEOUT) as client:
            if provider == "anthropic":
                r = client.post(
                    "https://api.anthropic.com/v1/messages",
                    headers={"x-api-key": settings.LLM_API_KEY, "anthropic-version": "2023-06-01"},
                    json={"model": _model(), "max_tokens": max_tokens, "system": system,
                          "messages": [{"role": "user", "content": prompt}]},
                )
                r.raise_for_status()
                return "".join(b.get("text", "") for b in r.json()["content"]).strip()
            if provider == "openai":
                r = client.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers={"Authorization": f"Bearer {settings.LLM_API_KEY}"},
                    json={"model": _model(), "max_tokens": max_tokens,
                          "messages": [{"role": "system", "content": system},
                                       {"role": "user", "content": prompt}]},
                )
                r.raise_for_status()
                return r.json()["choices"][0]["message"]["content"].strip()
            if provider == "ollama":
                r = client.post(
                    f"{settings.OLLAMA_URL.rstrip('/')}/api/chat",
                    json={"model": _model(), "stream": False,
                          "messages": [{"role": "system", "content": system},
                                       {"role": "user", "content": prompt}]},
                )
                r.raise_for_status()
                return r.json()["message"]["content"].strip()
    except httpx.HTTPStatusError as e:
        raise LLMError(f"LLM 서버 오류 ({e.response.status_code}): {e.response.text[:200]}") from e
    except (httpx.HTTPError, KeyError, IndexError, ValueError) as e:
        raise LLMError(f"LLM 호출 실패: {e}") from e
    raise LLMError(f"알 수 없는 LLM_PROVIDER: {settings.LLM_PROVIDER}")


def _mock(prompt: str) -> str:
    """API 키 없이 앱 화면을 만들 수 있도록 형식만 맞춘 예시 응답"""
    if "제목 후보" in prompt:
        return "\n".join([
            "함께 성장할 신입 부원을 모집합니다",
            "지금 지원하면 새 학기가 달라져요",
            "초보도 환영! 신입 부원 모집 안내",
            "이번 학기, 우리와 함께할 사람?",
            "동아리 신입 부원 모집 (마감 임박)",
        ])
    if "요약" in prompt:
        return "[예시 요약] 신입 부원 모집 안내이며, 지원 기간과 활동 내용을 확인 후 신청하면 됩니다."
    if "다듬어" in prompt:
        return "[예시 개선문] 입력하신 문장을 더 읽기 쉽고 자연스럽게 다듬은 결과가 여기에 표시됩니다."
    return ("[예시 초안]\n안녕하세요! 저희 동아리에서 함께할 신입 부원을 모집합니다.\n\n"
            "■ 활동 내용: (입력한 키워드 기반으로 작성)\n■ 모집 기간: \n■ 지원 방법: 앱에서 가입 신청\n\n"
            "많은 관심 부탁드립니다!")
