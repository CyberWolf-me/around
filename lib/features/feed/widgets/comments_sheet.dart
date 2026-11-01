import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/services/haptic_service.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  final String postTitle;

  const CommentsSheet({
    super.key,
    required this.postId,
    required this.postTitle,
  });

  static void show(BuildContext context, {required String postId, required String postTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentsSheet(postId: postId, postTitle: postTitle),
    );
  }

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final list = await ref.read(postsRepositoryProvider.notifier).fetchCommentsForPost(widget.postId);
    if (mounted) {
      setState(() {
        _comments = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    HapticService.light();
    setState(() => _isSubmitting = true);

    final err = await ref.read(postsRepositoryProvider.notifier).addCommentToPost(widget.postId, text);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.message), backgroundColor: AppColors.danger),
      );
    } else {
      _commentCtrl.clear();
      await _loadComments();
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.ink, width: 2),
          left: BorderSide(color: AppColors.ink, width: 2),
          right: BorderSide(color: AppColors.ink, width: 2),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
                      ),
                      Text(
                        widget.postTitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.paper3),
          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 36, color: AppColors.ink.withValues(alpha: 0.3)),
                            const SizedBox(height: 8),
                            const Text(
                              'No comments yet.\nBe the first to share your thoughts!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.ink2, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final comment = _comments[idx];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.butter,
                                child: Text(
                                  comment.authorAvatar ?? comment.authorName[0],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.ink),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.paper2,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.authorName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        comment.body,
                                        style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          const Divider(height: 1, color: AppColors.paper3),
          // Input bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: AppColors.paper2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.ink, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.ink, width: 1.8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSubmitting ? null : _submitComment,
                  style: IconButton.styleFrom(backgroundColor: AppColors.ink),
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
