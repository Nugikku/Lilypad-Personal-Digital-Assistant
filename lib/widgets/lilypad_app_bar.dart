import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/notes_screen.dart';

class LilypadAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showAvatar;
  final String? avatarUrl;

  const LilypadAppBar({
    super.key,
    this.title = 'Lilypad',
    this.leading,
    this.actions,
    this.showAvatar = true,
    this.avatarUrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.headerBg,
        border: Border(
          bottom: BorderSide(color: AppColors.headerBorder, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.headerBorder,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              if (showAvatar) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    border: Border.all(color: AppColors.headerBorder, width: 3),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.headerBorder,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: avatarUrl != null
                        ? Image.network(avatarUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.eco,
                              color: AppColors.headerBorder,
                              size: 20,
                            ),
                          )
                        : const Icon(
                            Icons.eco,
                            color: AppColors.headerBorder,
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.headerBorder,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              ...?actions,
              if (actions == null)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: AppColors.headerBorder, size: 28),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline,
                          color: AppColors.headerBorder, size: 28),
                      onPressed: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
