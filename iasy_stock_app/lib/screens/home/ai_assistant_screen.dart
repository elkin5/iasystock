import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/get_it_config.dart';
import '../../cubits/chat/ai_assistant_cubit.dart';
import '../../cubits/chat/ai_assistant_state.dart';
import '../../theme/home_layout_tokens.dart';
import '../../widgets/home/general_sliver_app_bar.dart';
import '../../widgets/home/home_ui_components.dart';

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AiAssistantCubit>(),
      child: const _AiAssistantView(),
    );
  }
}

class _AiAssistantView extends StatefulWidget {
  const _AiAssistantView();

  @override
  State<_AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<_AiAssistantView> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _pageScrollController = ScrollController();
  final DateFormat _timeFormatter = DateFormat('HH:mm');
  int _previousMessageCount = 0;

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageScrollController.hasClients) return;
      final position = _pageScrollController.position;
      _pageScrollController.animateTo(
        position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleSendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _messageFocusNode.requestFocus();
    context.read<AiAssistantCubit>().sendMessage(message);
    _scrollToBottom();
  }

  void _handleSuggestionTap(String suggestion) {
    context.read<AiAssistantCubit>().sendMessage(suggestion);
    _scrollToBottom();
  }

  Future<void> _handleClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar historial'),
        content: const Text(
          '¿Estás seguro de que deseas borrar todo el historial de conversación? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      unawaited(context.read<AiAssistantCubit>().clearHistory());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Historial borrado exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AiAssistantCubit, AiAssistantState>(
        listener: (context, state) {
          if (state is AiAssistantStateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AiAssistantStateLoaded) {
            // Solo hacer scroll si el número de mensajes cambió (se agregó uno nuevo)
            if (state.messages.length != _previousMessageCount) {
              _previousMessageCount = state.messages.length;
              _scrollToBottom();
            }
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    controller: _pageScrollController,
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      GeneralSliverAppBar(
                        title: 'Asistente IA',
                        subtitle:
                            'Consulta tu inventario con ayuda inteligente',
                        icon: Icons.smart_toy_rounded,
                        primaryColor: theme.primaryColor,
                        onLogout: (state is AiAssistantStateLoaded &&
                                state.messages.isNotEmpty)
                            ? _handleClearHistory
                            : null,
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(
                              HomeLayoutTokens.sectionPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildIntroSection(theme),
                              const SizedBox(
                                  height: HomeLayoutTokens.sectionSpacing),
                              if (state is AiAssistantStateLoadingUser)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: HomeLayoutTokens.sectionSpacing),
                                  child: _buildLoadingUserCard(theme),
                                )
                              else if (state is AiAssistantStateLoadingHistory)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: HomeLayoutTokens.sectionSpacing),
                                  child: _buildLoadingHistoryCard(theme),
                                )
                              else if (state is AiAssistantStateLoaded) ...[
                                _buildSuggestionsSection(theme, state),
                                const SizedBox(
                                    height: HomeLayoutTokens.sectionSpacing),
                                _buildConversationSection(theme, state),
                              ] else if (state is AiAssistantStateError)
                                _buildErrorCard(theme, state),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state is AiAssistantStateLoaded)
                  _buildInputSection(theme, !state.isSending),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntroSection(ThemeData theme) {
    return HomeSectionCard(
      addShadow: false,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: theme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente Inteligente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pregunta sobre tu inventario, productos, ventas y más',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingUserCard(ThemeData theme) {
    return HomeSectionCard(
      addShadow: false,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingHistoryCard(ThemeData theme) {
    return const HomeSectionCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Cargando historial...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, AiAssistantStateError state) {
    return HomeSectionCard(
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 12),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(
      ThemeData theme, AiAssistantStateLoaded state) {
    return HomeSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sugerencias rápidas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: HomeLayoutTokens.smallSpacing),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.suggestions
                .map(
                  (suggestion) => ActionChip(
                    label: Text(
                      suggestion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    avatar: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: theme.primaryColor,
                    ),
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    onPressed: state.isSending
                        ? null
                        : () => _handleSuggestionTap(suggestion),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationSection(
      ThemeData theme, AiAssistantStateLoaded state) {
    return HomeSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Conversación',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.messages.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No hay mensajes aún. ¡Inicia la conversación!'),
              ),
            )
          else
            ...state.messages.map((message) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMessageBubble(theme, message),
                )),
          if (state.isSending)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTypingIndicator(theme, state.elapsedSeconds),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, ChatMessage message) {
    final isUser = message.author == MessageAuthor.user;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor =
        isUser ? theme.primaryColor : theme.primaryColor.withValues(alpha: 0.1);
    final textColor = isUser ? Colors.white : theme.textTheme.bodyMedium?.color;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: borderRadius,
                ),
                child: Text(
                  message.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _timeFormatter.format(message.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme, int elapsedSeconds) {
    String elapsedText = '';
    if (elapsedSeconds > 0) {
      elapsedText = ' (${elapsedSeconds}s)';
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitThreeBounce(
                      color: theme.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'El asistente está escribiendo...$elapsedText',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (elapsedSeconds >= 2) ...[
                  const SizedBox(height: 12),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (elapsedSeconds >= 2)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Consultando base de datos y generando respuesta...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme, bool canSend) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              enabled: canSend,
              decoration: InputDecoration(
                hintText: 'Escribe tu consulta...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: canSend ? (_) => _handleSendMessage() : null,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: canSend ? _handleSendMessage : null,
            mini: true,
            child: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
