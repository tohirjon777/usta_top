<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\WorkshopController;
use Illuminate\Support\Facades\Route;

Route::get('/health', HealthController::class);

Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/register/send-code', [AuthController::class, 'sendRegisterCode']);
Route::post('/auth/register/verify-code', [AuthController::class, 'verifyRegisterCode']);
Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/auth/password/send-code', [AuthController::class, 'sendPasswordResetCode']);
Route::post('/auth/password/verify-code', [AuthController::class, 'verifyPasswordResetCode']);
Route::post('/auth/push-token', [AuthController::class, 'registerPushToken']);
Route::post('/auth/push-token/remove', [AuthController::class, 'unregisterPushToken']);
Route::post('/auth/push-token/test', [AuthController::class, 'sendTestPush']);
Route::get('/auth/me', [AuthController::class, 'me']);
Route::patch('/auth/me', [AuthController::class, 'updateMe']);
Route::post('/auth/me/cards', [AuthController::class, 'addPaymentCard']);
Route::patch('/auth/me/cards/{cardId}', [AuthController::class, 'updatePaymentCard']);
Route::delete('/auth/me/cards/{cardId}', [AuthController::class, 'deletePaymentCard']);
Route::patch('/auth/me/password', [AuthController::class, 'updatePassword']);

Route::get('/workshops', [WorkshopController::class, 'index']);
Route::get('/workshops/{id}', [WorkshopController::class, 'show']);
Route::get('/workshops/{id}/availability', [WorkshopController::class, 'availability']);
Route::get('/workshops/{id}/availability/calendar', [WorkshopController::class, 'availabilityCalendar']);
Route::get('/workshops/{id}/price-quote', [WorkshopController::class, 'priceQuote']);
Route::post('/workshops/{id}/reviews', [WorkshopController::class, 'createReview']);

Route::get('/bookings', [BookingController::class, 'index']);
Route::post('/bookings', [BookingController::class, 'store']);
Route::patch('/bookings/{id}/cancel', [BookingController::class, 'cancel']);
Route::patch('/bookings/{id}/reschedule', [BookingController::class, 'reschedule']);
Route::patch('/bookings/{id}/accept-reschedule', [BookingController::class, 'acceptRescheduled']);
Route::get('/bookings/{id}/messages', [BookingController::class, 'messages']);
Route::post('/bookings/{id}/messages', [BookingController::class, 'sendMessage']);
Route::patch('/bookings/{id}/messages/read', [BookingController::class, 'markMessagesRead']);
