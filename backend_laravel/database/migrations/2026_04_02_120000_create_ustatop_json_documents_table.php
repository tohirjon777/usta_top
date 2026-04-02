<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $tableName = (string) config('ustatop.storage_db_table', 'ustatop_json_documents');

        if (Schema::hasTable($tableName)) {
            return;
        }

        Schema::create($tableName, function (Blueprint $table): void {
            $table->string('document_hash', 64)->primary();
            $table->longText('document_key');
            $table->longText('payload');
            $table->string('updated_at', 64);
        });
    }

    public function down(): void
    {
        $tableName = (string) config('ustatop.storage_db_table', 'ustatop_json_documents');
        Schema::dropIfExists($tableName);
    }
};
