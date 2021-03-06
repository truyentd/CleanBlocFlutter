import 'dart:async';
import '../log/log_utils.dart';

class DisposeBag {
  final List<Object> _disposable = [];

  void addDisposable(Object disposable) {
    _disposable.add(disposable);
  }

  void dispose() {
    _disposable.forEach((disposable) {
      if (disposable is StreamSubscription) {
        printKV(tag, 'disposed $disposable');
        disposable.cancel();
      } else if (disposable is StreamController) {
        printKV(tag, 'disposed $disposable');
        disposable.close();
      }
    });
  }

  static const tag = 'DisposeBag';
}

extension DisposableStreamSubscription on StreamSubscription {
  void disposeBy(DisposeBag disposeBag) {
    disposeBag.addDisposable(this);
  }
}

extension DisposableStreamController on StreamController {
  void disposeBy(DisposeBag disposeBag) {
    disposeBag.addDisposable(this);
  }
}
