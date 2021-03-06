import 'package:auto_route/auto_route.dart';
import '../app_bloc.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

import '../../../data/source/local/preference/error/shared_pref_exception.dart';
import '../../../data/source/remote/api/error/http_request_exception.dart';
import '../../../data/source/remote/api/error/parse_json_exception.dart';
import '../../../data/source/remote/api/error/server_error_constants.dart';
import '../../../generated/l10n.dart';
import '../../../utils/stream/dispose_bag.dart';
import '../../../utils/utils.dart';
import 'base_bloc.dart';

abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);
}

abstract class BaseState<Screen extends BaseScreen, Bloc extends BaseBloc>
    extends State<Screen> {
  final Bloc bloc = GetIt.instance.get<Bloc>();
  final AppBloc appBloc = GetIt.instance.get<AppBloc>();
  final errorVisibleDuration = const Duration(seconds: 3);
  final disposeBag = DisposeBag();

  @override
  void initState() {
    super.initState();
    bloc
      ..errorStream.throttleTime(errorVisibleDuration).listen(handleError)
      ..loadingStream.scan<int>((accumulated, value, _) {
        if (value)
          return accumulated + 1;
        else
          return accumulated - 1;
      }, 0).listen((loadingCount) {
        if (loadingCount == 1) {
          showLoading();
        } else if (loadingCount <= 0) {
          hideLoading();
        }
      });
  }

  @override
  void dispose() {
    disposeBag.dispose();
    bloc.dispose();
    super.dispose();
  }

  void handleError(Object error) {
    if (error is HttpRequestException) {
      switch (error.kind) {
        case HttpRequestExceptionKind.server:
          switch (error.getFirstServerErrorCode()) {
            case ServerErrorCode.invalidRefreshToken:
            case ServerErrorCode.accountHasDeleted:
            case ServerErrorCode.multipleDeviceLogin:

              /// force logout
              context.showAlertDialog(
                  error.getFirstServerErrorMessage() ??
                      S.of(context).unexpected_error,
                  () {
                    appBloc.onClearAllUserInfo();
                  });
              break;
            default:
              onServerError(error);
              break;
          }

          break;
        case HttpRequestExceptionKind.http:
          if (error.isServerDownError) {
            showErrorSnackBar(S.of(context).server_down_error);
          } else {
            showErrorSnackBar(S.of(context).unexpected_error);
          }
          break;
        case HttpRequestExceptionKind.noInternet:
          showErrorSnackBar(S.of(context).check_connection);
          break;
        case HttpRequestExceptionKind.network:
          showErrorSnackBar(S.of(context).server_problem_try_later);
          break;
        case HttpRequestExceptionKind.timeout:
          showErrorSnackBar(S.of(context).check_connection);
          break;
        case HttpRequestExceptionKind.cancellation:
          break;
        case HttpRequestExceptionKind.unexpected:
          showErrorSnackBar(S.of(context).unexpected_error);
          break;
      }
    } else if (error is SharedPrefException) {
      showErrorSnackBar(S.of(context).unexpected_error);
    } else if (error is ParseJsonException) {
      showErrorSnackBar(S.of(context).unexpected_error);
    } else {
      showErrorSnackBar(S.of(context).unexpected_error);
    }
  }

  void showErrorSnackBar(String message) {
    context.showSnackBar(message, errorVisibleDuration);
  }

  void onServerError(HttpRequestException exception) {
    final message = exception.getFirstServerErrorMessage() ??
        S.of(context).unexpected_error;
    showErrorSnackBar(message);
  }

  void showLoading() {
    context.showLoading();
  }

  void hideLoading() {
    AutoRouter.of(context).pop();
  }
}
