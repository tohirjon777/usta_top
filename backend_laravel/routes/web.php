<?php

use App\Http\Controllers\Web\CustomerWebsiteController;
use App\Http\Controllers\Web\WorkshopMediaController;
use Illuminate\Support\Facades\Route;

Route::get('/', [CustomerWebsiteController::class, 'home']);
Route::get('/workshop/{id}', [CustomerWebsiteController::class, 'workshop']);
Route::get('/customer/login', [CustomerWebsiteController::class, 'loginPage']);
Route::post('/customer/login', [CustomerWebsiteController::class, 'login']);
Route::post('/customer/register', [CustomerWebsiteController::class, 'register']);
Route::post('/customer/logout', [CustomerWebsiteController::class, 'logout']);
Route::get('/customer/account', [CustomerWebsiteController::class, 'accountPage']);
Route::post('/customer/profile', [CustomerWebsiteController::class, 'updateProfile']);
Route::post('/customer/password', [CustomerWebsiteController::class, 'updatePassword']);
Route::post('/customer/cards', [CustomerWebsiteController::class, 'addCard']);
Route::post('/customer/cards/{cardId}/update', [CustomerWebsiteController::class, 'updateCard']);
Route::post('/customer/cards/{cardId}/delete', [CustomerWebsiteController::class, 'deleteCard']);
Route::post('/customer/workshops/{id}/book', [CustomerWebsiteController::class, 'createBooking']);
Route::post('/customer/workshops/{id}/reviews', [CustomerWebsiteController::class, 'createReview']);
Route::post('/customer/bookings/{id}/cancel', [CustomerWebsiteController::class, 'cancelBooking']);
Route::post('/customer/bookings/{id}/reschedule', [CustomerWebsiteController::class, 'rescheduleBooking']);
Route::post('/customer/bookings/{id}/accept-reschedule', [CustomerWebsiteController::class, 'acceptRescheduled']);
Route::post('/customer/bookings/{id}/messages', [CustomerWebsiteController::class, 'sendMessage']);
Route::get('/media/workshops/{filename}', [WorkshopMediaController::class, 'showWorkshopImage'])
    ->where('filename', '[A-Za-z0-9._-]+');
