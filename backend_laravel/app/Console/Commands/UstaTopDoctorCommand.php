<?php

namespace App\Console\Commands;

use App\Support\UstaTop\UstaTopDoctor;
use Illuminate\Console\Command;

class UstaTopDoctorCommand extends Command
{
    protected $signature = 'ustatop:doctor {--json} {--strict}';

    protected $description = 'Run UstaTop production readiness checks.';

    public function __construct(
        private readonly UstaTopDoctor $doctor,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $strict = (bool) $this->option('strict');
        $summary = $this->doctor->summary($strict);

        if ((bool) $this->option('json')) {
            $this->line(json_encode($summary, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));

            return $summary['ok'] ? self::SUCCESS : self::FAILURE;
        }

        $this->info('UstaTop Doctor');
        $this->newLine();

        foreach ($summary['checks'] as $check) {
            $prefix = match ($check['status']) {
                'pass' => 'PASS',
                'warn' => 'WARN',
                default => 'FAIL',
            };

            $line = sprintf('[%s] %s: %s', $prefix, $check['label'], $check['message']);

            match ($check['status']) {
                'pass' => $this->line($line),
                'warn' => $this->warn($line),
                default => $this->error($line),
            };
        }

        $this->newLine();
        if ($summary['ok']) {
            $this->info($summary['hasWarnings'] ? 'Doctor warnings with success.' : 'Doctor passed.');

            return self::SUCCESS;
        }

        $this->error('Doctor failed.');

        return self::FAILURE;
    }
}
