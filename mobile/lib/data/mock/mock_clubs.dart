import '../models/club.dart';

/// 서버 API가 준비되기 전까지 화면 개발에 사용하는 가짜 데이터
const List<Club> mockClubs = [
  Club(
    id: 1,
    name: 'CATS',
    category: '학술',
    summary: '코딩 스터디 동아리입니다.',
    description: '알고리즘, 웹·앱 개발 스터디와 프로젝트를 함께하는 컴퓨터 학술 동아리',
    isRecruiting: true,
    memberCount: 42,
  ),
  Club(
    id: 2,
    name: 'COSMIC',
    category: '학술',
    summary: '천문 관측 동아리입니다.',
    description: '정기 관측회와 천체 사진 촬영을 하는 천문 동아리입니다.',
    isRecruiting: false,
    memberCount: 25,
  ),
  Club(
    id: 3,
    name: 'IPSE',
    category: '봉사',
    summary: '봉사 활동 동아리입니다.',
    description: '지역 아동센터 교육 봉사와 환경 정화 활동을 하는 봉사 동아리',
    isRecruiting: true,
    memberCount: 31,
  ),
  Club(
    id: 4,
    name: 'CERT',
    category: '학술',
    summary: '정보보안 연구 동아리입니다.',
    description: '해킹 대회(CTF) 참가와 보안 스터디를 하는 정보보안 동아리입니다.',
    isRecruiting: false,
    memberCount: 18,
  ),
  Club(
    id: 5,
    name: '울림',
    category: '예술',
    summary: '밴드 공연 동아리입니다.',
    description: '정기 공연과 축제 무대를 준비하는 밴드 동아리입니다.',
    isRecruiting: true,
    memberCount: 27,
  ),
  Club(
    id: 6,
    name: 'FC 개신',
    category: '체육',
    summary: '축구 동아리입니다.',
    description: '주 2회 정기 훈련과 교내외 리그에 참가하는 축구 동아리입니다.',
    isRecruiting: true,
    memberCount: 35,
  ),
];
