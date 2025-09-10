import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/timer/timer_page.dart';
import 'services/db.dart';
import 'providers/db_provider.dart';
import 'providers/session_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DB.instance(); // Isar 미리 오픈(선택)
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Sessions'),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isarAsync = ref.watch(isarProvider);
    final filter = ref.watch(sessionFilterProvider);

    return isarAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('DB error: $e'))),
      data: (_) {
        final sessionsAsync = ref.watch(sessionsStreamProvider);
        return Scaffold(
          appBar: AppBar(
            title: Text('$title (${filter.name})'),
            actions: [
              // ⏱ 타이머 페이지로 이동 버튼 추가
              IconButton(
                tooltip: 'Timer',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TimerPage()),
                  );
                },
                icon: const Icon(Icons.timer_outlined),
              ),
              PopupMenuButton<SessionFilter>(
                initialValue: filter,
                onSelected: (f) => ref.read(sessionFilterProvider.notifier).state = f,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: SessionFilter.all, child: Text('전체')),
                  PopupMenuItem(value: SessionFilter.today, child: Text('오늘')),
                  PopupMenuItem(value: SessionFilter.week, child: Text('이번 주')),
                ],
              ),
              IconButton(
                tooltip: '더미 추가',
                onPressed: () => ref.read(addDemoSessionProvider.future),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: sessionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('세션 로드 오류: $e')),
            data: (list) {
              if (list.isEmpty) {
                return const Center(child: Text('세션이 없습니다. 오른쪽 위 + 로 추가해보세요.'));
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = list[i];
                  return Dismissible(
                    key: ValueKey(s.id),
                    background: Container(color: Colors.red),
                    onDismissed: (_) {
                      ref.read(deleteSessionProvider(s.id).future);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('삭제됨')),
                      );
                    },
                    child: ListTile(
                      title: Text('${s.mode} • ${(s.durationSeconds / 60).toStringAsFixed(1)}분'),
                      subtitle: Text(
                        '${s.startTime} ~ ${s.endTime}${s.note != null ? '\n${s.note}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref.read(deleteSessionProvider(s.id).future),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
