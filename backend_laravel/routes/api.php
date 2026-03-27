<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\WorkshopController;
use Illuminate\Support\Facades\Route;

Route::get('/health', HealthController::class);

Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);
Route::get('/auth/me', [AuthController::class, 'me']);

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
