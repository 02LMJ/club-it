import 'package:flutter/material.dart';

void main() {
  runApp(const ClubItApp());
}

class ClubItApp extends StatelessWidget {
  const ClubItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Club-it',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
        ),
        useMaterial3: true,
      ),
      home: const ClubHomePage(),
    );
  }
}

class ClubHomePage extends StatefulWidget {
  const ClubHomePage({super.key});

  @override
  State<ClubHomePage> createState() => _ClubHomePageState();
}

class _ClubHomePageState extends State<ClubHomePage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _clubs = [
    {
      'name': 'CATS',
      'category': '학술',
      'description': '코딩 스터디 동아리입니다.',
      'favorite': true,
    },
    {
      'name': 'COSMIC',
      'category': '문화',
      'description': '천문 관측 동아리입니다.',
      'favorite': false,
    },
    {f
      'name': 'IPSE',
      'category': '봉사',
      'description': '봉사 활동 동아리입니다.',
      'favorite': false,
    },
  ];

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final filteredClubs = _clubs.where((club) {
      final name = club['name'].toString().toLowerCase();
      final category = club['category'].toString().toLowerCase();
      final keyword = _searchText.toLowerCase();

      return name.contains(keyword) || category.contains(keyword);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Club-it',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '동아리 검색',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: '동아리 이름 또는 카테고리 검색',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '동아리 목록',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '전체보기',
                    style: TextStyle(
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Expanded(
                child: filteredClubs.isEmpty
                    ? const Center(
                        child: Text('검색 결과가 없습니다.'),
                      )
                    : ListView.separated(
                        itemCount: filteredClubs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final club = filteredClubs[index];

                          return ClubCard(
                            name: club['name'],
                            category: club['category'],
                            description: club['description'],
                            favorite: club['favorite'],
                            onFavoritePressed: () {
                              setState(() {
                                club['favorite'] = !club['favorite'];
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: '즐겨찾기',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}

class ClubCard extends StatelessWidget {
  final String name;
  final String category;
  final String description;
  final bool favorite;
  final VoidCallback onFavoritePressed;

  const ClubCard({
    super.key,
    required this.name,
    required this.category,
    required this.description,
    required this.favorite,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFECEBFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.groups,
                color: Color(0xFF6C63FF),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    category,
                    style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: onFavoritePressed,
              icon: Icon(
                favorite ? Icons.star : Icons.star_border,
                color: favorite ? Colors.amber : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}