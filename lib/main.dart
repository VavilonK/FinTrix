import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/state/app_controller.dart';
import 'core/storage/app_database.dart';
import 'core/storage/app_state_repository.dart';
import 'features/adult/data/local_parent_biometric_authenticator.dart';
import 'features/adult/data/secure_parent_credential_store.dart';
import 'features/adult/domain/parent_access_service.dart';
import 'features/finance/data/financial_transaction_repository.dart';
import 'features/periods/domain/game_period.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final repository = AppStateRepository(database);
  final financialTransactions = FinancialTransactionRepository(database);
  final parentAccessService = ParentAccessService(
    SecureParentCredentialStore(),
    LocalParentBiometricAuthenticator(),
  );
  final parentProfile = await repository.loadParentProfile();
  final storedState = parentProfile.parentSetupCompleted
      ? await repository.load()
      : await repository.loadProfile(AppRunMode.normal);
  final canSaveStartupState = !storedState.isCorrupted;
  late final AppController controller;

  if (storedState.snapshot case final snapshot?) {
    controller = AppController.fromSnapshot(
      snapshot: snapshot,
      repository: repository,
      financialTransactions: financialTransactions,
      parentProfile: parentProfile,
      parentAccessService: parentAccessService,
    );
  } else if (storedState.isCorrupted) {
    // Keep the unreadable row intact for diagnostics/recovery. Autosave stays
    // disabled until the user explicitly chooses the existing reset action.
    controller = AppController(
      repository: repository,
      financialTransactions: financialTransactions,
      parentProfile: parentProfile,
      parentAccessService: parentAccessService,
      persistenceEnabled: false,
    );
  } else {
    controller = AppController(
      repository: repository,
      financialTransactions: financialTransactions,
      parentProfile: parentProfile,
      parentAccessService: parentAccessService,
    );
  }

  if (controller.parentSetupCompleted) controller.missionForToday();
  if (canSaveStartupState && controller.parentSetupCompleted) {
    await repository.save(controller.toSnapshot());
  }

  runApp(App(controller: controller));
}
