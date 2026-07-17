import 'package:buy_control/core/errors/app_failure.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R fold<R>(R Function(T data) onSuccess, R Function(AppFailure failure) onFailure) {
    final self = this;
    if (self is Success<T>) return onSuccess(self.data);
    return onFailure((self as Failure<T>).failure);
  }

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  AppFailure? get failureOrNull => this is Failure<T> ? (this as Failure<T>).failure : null;
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}
