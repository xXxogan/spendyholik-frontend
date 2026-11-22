import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/user/data/repositories/privacy_policy_repository.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final _repository = getIt<PrivacyPolicyRepository>();
  late Future<String> _policy = _repository.load();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppGlassScaffold(
      leading: const AppBackButton(fallback: RegisterRoute()),
      title: l10n.privacyTitle,
      body: BaseLayout.slivers(
        largeTitle: l10n.privacyTitle,
        slivers: [
          ContentSliverPadding(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const .only(top: 12, bottom: 24),
                child: FutureBuilder<String>(
                  future: _policy,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return FailureView(
                        failure: const UnknownFailure(),
                        onRetry: () => setState(() {
                          _policy = _repository.load();
                        }),
                      );
                    }
                    if (snapshot.data case final document?) {
                      return _PolicyDocument(document: document);
                    }
                    return const SkeletonList(itemCount: 3);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyDocument extends StatelessWidget {
  const _PolicyDocument({required this.document});

  final String document;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final blocks = document.trim().split(RegExp(r'\r?\n[ \t]*\r?\n'));

    return SelectionArea(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 16,
        children: [
          for (final block in blocks.skip(1))
            if (block.startsWith('## ') || block.startsWith('### '))
              Semantics(
                header: true,
                child: Text(
                  block.substring(block.indexOf(' ') + 1),
                  style: block.startsWith('## ')
                      ? text.titleLarge
                      : text.titleMedium,
                ),
              )
            else
              Text.rich(
                TextSpan(
                  children: [
                    for (final (index, part) in block.split('**').indexed)
                      TextSpan(
                        text: part,
                        style: index.isOdd
                            ? const TextStyle(fontWeight: .w700)
                            : null,
                      ),
                  ],
                ),
                style: text.bodyLarge?.copyWith(height: 1.5),
              ),
        ],
      ),
    );
  }
}
