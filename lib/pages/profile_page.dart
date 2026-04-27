import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await ApiService.getProfile();
    if (mounted) setState(() {});
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              ApiService.logout();
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                builder: (_) => const LoginPage(),
              ), (route) => false);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ApiService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 个人信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        (user?.username ?? '?').substring(0, 1).toUpperCase(),
                        style: TextStyle(fontSize: 28, color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.username ?? '未登录', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(user?.email ?? '', style: TextStyle(color: Colors.grey.shade600)),
                          if (user != null && user.vip.isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('👑 ${user.vip.levelName}', style: TextStyle(fontSize: 13, color: Colors.amber.shade800)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // VIP 信息卡片
            if (user != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VIP 信息', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _infoRow(Icons.crown, '等级', user.vip.levelName),
                      const SizedBox(height: 8),
                      _infoRow(Icons.timer_outlined, '状态', user.vip.isActive ? '✅ 有效' : '❌ 未开通'),
                      if (user.vip.expiresAt != null) ...[
                        const SizedBox(height: 8),
                        _infoRow(Icons.event, '到期时间', user.vip.expiresAt!.substring(0, 10)),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 操作按钮
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('关于'),
                    subtitle: const Text('v1.0.0'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: '北川的 App',
                        applicationVersion: '1.0.0',
                        children: [
                          const Text('基于 Flask + Flutter 构建的聊天应用'),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('退出登录', style: TextStyle(color: Colors.red)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text('$label：', style: TextStyle(color: Colors.grey.shade600)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
