<?php

use App\Http\Controllers\Web\AdminController;
use App\Http\Controllers\Web\OwnerController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect('/admin/login'));

Route::get('/admin', [AdminController::class, 'entry']);
Route::get('/admin/login', [AdminController::class, 'loginPage']);
Route::post('/admin/login', [AdminController::class, 'login']);
Route::post('/admin/logout', [AdminController::class, 'logout']);
Route::get('/admin/workshops', [AdminController::class, 'workshopsPage']);
Route::get('/admin/bookings', [AdminController::class, 'bookingsPage']);
Route::post('/admin/bookings/{id}/status', [AdminController::class, 'updateBookingStatus']);

Route::get('/owner', [OwnerController::class, 'entry']);
Route::get('/owner/login', [OwnerController::class, 'loginPage']);
Route::post('/owner/login', [OwnerController::class, 'login']);
Route::post('/owner/logout', [OwnerController::class, 'logout']);
Route::get('/owner/bookings', [OwnerController::class, 'bookingsPage']);
Route::post('/owner/bookings/{id}/status', [OwnerController::class, 'updateStatus']);
