"""LLM 기반 콘텐츠 작성 보조: 제목추천 / 본문초안 / 문장개선 / 요약."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.llm import LLMError, generate
from app.models import User
from app.schemas import POST_TYPE_LABELS, AssistRequest, AssistResponse
from app.security import get_club_or_404, get_current_user

router = APIRouter(prefix="/ai", tags=["LLM 작성보조"])

SYSTEM = (
    "너는 대학교 동아리 앱 'Club-it'의 글쓰기 도우미다. "
    "대학생이 읽기 편한 친근하고 명확한 한국어로 쓴다. "
    "사실을 지어내지 말고, 정보가 없으면 '(입력 필요)'처럼 빈칸으로 남긴다. "
    "요청한 결과만 출력하고 인사말이나 설명은 붙이지 않는다."
)


def _build_prompt(req: AssistRequest, club_info: str) -> str:
    kind = POST_TYPE_LABELS[req.post_type]
    base = f"글 종류: {kind}\n{club_info}"
    if req.task == "title":
        return f"{base}\n아래 본문에 어울리는 제목 후보 5개를 한 줄에 하나씩, 번호 없이 30자 이내로 써줘.\n\n본문:\n{req.text}"
    if req.task == "draft":
        return (f"{base}\n아래 키워드/메모를 바탕으로 {kind} 본문 초안을 써줘. "
                f"모집 기간, 장소처럼 메모에 없는 정보는 '(입력 필요)'로 남겨줘.\n\n키워드/메모:\n{req.text}")
    if req.task == "improve":
        return f"{base}\n아래 글의 의미는 유지하고 맞춤법과 문장을 자연스럽게 다듬어줘.\n\n원문:\n{req.text}"
    return f"{base}\n아래 글을 앱 목록 미리보기용으로 2~3문장 요약해줘.\n\n원문:\n{req.text}"


@router.post("/assist", response_model=AssistResponse)
def assist(req: AssistRequest, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    if req.task != "draft" and not req.text.strip():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "text에 대상 본문을 입력해주세요.")
    club_info = ""
    if req.club_id is not None:
        c = get_club_or_404(db, req.club_id)
        club_info = f"동아리: {c.club_name} (분야: {c.category or '미지정'})\n소개: {c.description or '없음'}\n"
    try:
        text = generate(SYSTEM, _build_prompt(req, club_info))
    except LLMError as e:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(e))
    suggestions: list[str] = []
    if req.task == "title":
        suggestions = [s.strip(" -•*0123456789.)\"'") for s in text.splitlines() if s.strip()][:5]
    return AssistResponse(task=req.task, result=text, suggestions=suggestions, provider=settings.LLM_PROVIDER)
