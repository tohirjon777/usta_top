<?php

namespace Tests\Feature;

use App\Support\UstaTop\UstaTopRepository;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Http;
use Tests\Concerns\UsesIsolatedUstaTopData;
use Tests\TestCase;

class UstaTopTelegramCallbackCommandTest extends TestCase
{
    use UsesIsolatedUstaTopData;

    protected function setUp(): void
    {
        parent::setUp();
        $this->setUpUstaTopData();
        config()->set('services.telegram.bot_token', 'test-token');
    }

    protected function tearDown(): void
    {
        $this->tearDownUstaTopData();
        parent::tearDown();
    }

    public function test_callback_command_accepts_booking_from_telegram_button(): void
    {
        $repository = app(UstaTopRepository::class);
        $this->linkWorkshopChat($repository);

        Http::fake([
            'https://api.telegram.org/*/getUpdates*' => Http::response([
                'ok' => true,
                'result' => [[
                    'update_id' => 101,
                    'callback_query' => [
                        'id' => 'cb-1',
                        'data' => 'a:b-seed-1',
                        'message' => [
                            'message_id' => 77,
                            'chat' => ['id' => '99887766'],
                        ],
                    ],
                ]],
            ], 200),
            'https://api.telegram.org/*/answerCallbackQuery' => Http::response([
                'ok' => true,
                'result' => true,
            ], 200),
            'https://api.telegram.org/*/editMessageText' => Http::response([
                'ok' => true,
                'result' => ['message_id' => 77],
            ], 200),
        ]);

        Artisan::call('ustatop:telegram-poll', ['--once' => true]);

        $booking = $repository->bookingById('b-seed-1');
        $this->assertSame('accepted', (string) ($booking['status'] ?? ''));
    }

    public function test_callback_command_opens_reschedule_options_from_telegram_button(): void
    {
        $repository = app(UstaTopRepository::class);
        $this->linkWorkshopChat($repository);

        Http::fake([
            'https://api.telegram.org/*/getUpdates*' => Http::response([
                'ok' => true,
                'result' => [[
                    'update_id' => 102,
                    'callback_query' => [
                        'id' => 'cb-2',
                        'data' => 'r:b-seed-1',
                        'message' => [
                            'message_id' => 78,
                            'chat' => ['id' => '99887766'],
                        ],
                    ],
                ]],
            ], 200),
            'https://api.telegram.org/*/answerCallbackQuery' => Http::response([
                'ok' => true,
                'result' => true,
            ], 200),
            'https://api.telegram.org/*/editMessageText' => Http::response([
                'ok' => true,
                'result' => ['message_id' => 78],
            ], 200),
        ]);

        Artisan::call('ustatop:telegram-poll', ['--once' => true]);

        Http::assertSent(function ($request): bool {
            if (! str_contains($request->url(), '/editMessageText')) {
                return false;
            }

            $data = $request->data();

            return str_contains((string) ($data['text'] ?? ''), 'yangi vaqtni tanlang')
                && isset($data['reply_markup']['inline_keyboard']);
        });
    }

    public function test_callback_command_reschedules_booking_from_selected_telegram_slot(): void
    {
        $repository = app(UstaTopRepository::class);
        $this->linkWorkshopChat($repository);

        $booking = $repository->bookingById('b-seed-1');
        $this->assertNotNull($booking);

        $suggestions = $repository->suggestedRescheduleSlots(
            'w-1',
            (string) ($booking['serviceId'] ?? ''),
            (string) ($booking['dateTime'] ?? ''),
            'b-seed-1',
        );

        $this->assertNotSame([], $suggestions);

        $slotCode = CarbonImmutable::parse($suggestions[0])
            ->setTimezone(config('app.timezone'))
            ->format('YmdHi');

        Http::fake([
            'https://api.telegram.org/*/getUpdates*' => Http::response([
                'ok' => true,
                'result' => [[
                    'update_id' => 103,
                    'callback_query' => [
                        'id' => 'cb-3',
                        'data' => 's:'.$slotCode.':b-seed-1',
                        'message' => [
                            'message_id' => 79,
                            'chat' => ['id' => '99887766'],
                        ],
                    ],
                ]],
            ], 200),
            'https://api.telegram.org/*/answerCallbackQuery' => Http::response([
                'ok' => true,
                'result' => true,
            ], 200),
            'https://api.telegram.org/*/editMessageText' => Http::response([
                'ok' => true,
                'result' => ['message_id' => 79],
            ], 200),
        ]);

        Artisan::call('ustatop:telegram-poll', ['--once' => true]);

        $updated = $repository->bookingById('b-seed-1');
        $this->assertSame('rescheduled', (string) ($updated['status'] ?? ''));
        $this->assertSame('owner_telegram', (string) ($updated['rescheduledByRole'] ?? ''));
        $this->assertNotSame('', (string) ($updated['previousDateTime'] ?? ''));
    }

    public function test_callback_command_opens_specific_reschedule_page_from_navigation_button(): void
    {
        $repository = app(UstaTopRepository::class);
        $this->linkWorkshopChat($repository);

        $booking = $repository->bookingById('b-seed-1');
        $this->assertNotNull($booking);

        $page = $repository->rescheduleSlotPage(
            'w-1',
            (string) ($booking['serviceId'] ?? ''),
            (string) ($booking['dateTime'] ?? ''),
            'b-seed-1',
        );

        $this->assertNotNull($page['nextOffset'] ?? null);

        Http::fake([
            'https://api.telegram.org/*/getUpdates*' => Http::response([
                'ok' => true,
                'result' => [[
                    'update_id' => 104,
                    'callback_query' => [
                        'id' => 'cb-4',
                        'data' => 'r:'.$page['nextOffset'].':b-seed-1',
                        'message' => [
                            'message_id' => 80,
                            'chat' => ['id' => '99887766'],
                        ],
                    ],
                ]],
            ], 200),
            'https://api.telegram.org/*/answerCallbackQuery' => Http::response([
                'ok' => true,
                'result' => true,
            ], 200),
            'https://api.telegram.org/*/editMessageText' => Http::response([
                'ok' => true,
                'result' => ['message_id' => 80],
            ], 200),
        ]);

        Artisan::call('ustatop:telegram-poll', ['--once' => true]);

        Http::assertSent(function ($request): bool {
            if (! str_contains($request->url(), '/editMessageText')) {
                return false;
            }

            $payload = json_encode($request->data());

            return str_contains((string) $payload, 'Oldingi kun')
                && str_contains((string) $payload, 'Ortga');
        });
    }

    private function linkWorkshopChat(UstaTopRepository $repository): void
    {
        $workshop = $repository->workshopById('w-1');
        $repository->updateWorkshop('w-1', array_merge($workshop, [
            'telegramChatId' => '99887766',
            'telegramChatLabel' => 'usta_top_owner',
            'telegramLinkCode' => '',
        ]));
    }
}
