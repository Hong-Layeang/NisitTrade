import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../logic/view_models/saved_listings_view_model.dart';
import '../../../logic/view_models/marketplace_view_model.dart';
import '../../../logic/view_models/search_view_model.dart';
import 'widgets/auth_footer_links.dart';
import 'widgets/join_waitlist_dialog.dart';
import 'widgets/white_blur_gradient.dart';
import '../../widgets/app_buttons.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    // Clear all ViewModels when user reaches welcome page
    // This ensures no data persists between user sessions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductFeedViewModel>().clear();
        context.read<UserViewModel>().clear();
        context.read<SavedListingsViewModel>().clear();
        context.read<MarketplaceViewModel>().clear();
        context.read<SearchViewModel>().clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    // Banner Image with white blur at bottom
                    SizedBox(
                      width: double.infinity,
                      height: constraints.maxHeight * 0.5,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/onboarding/banner.png',
                            fit: BoxFit.cover,
                          ),
                          // White blur gradient at bottom
                          const WhiteBlurGradient(),
                        ],
                      ),
                    ),

                    // Content Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome to NisitTrade',
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Buy. Sell.\n',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Repeat the magic.',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sign in to connect with your community',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: AppPrimaryButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, AppRoutes.login);
                                  },
                                  label: 'LOGIN',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppSecondaryButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, AppRoutes.signup);
                                  },
                                  label: 'SIGN UP',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Join Community Section
                          Text(
                            'Looking for NisitTrade at your school ?',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              JoinWaitlistDialog.show(context);
                            },
                            child: const Text(
                              'Join community',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Footer Links
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24, top: 8),
                      child: AuthFooterLinks(
                        onTermsTap: () async {
                          final uri = Uri.parse('https://nisittrade.com/terms');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        onPrivacyTap: () async {
                          final uri = Uri.parse('https://nisittrade.com/privacy');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
