#!/bin/bash

# issue 1: currency_parser.dart
sed -i 's/} catch (_) {/} catch (e, s) {/g' lib/core/utils/currency_parser.dart

# issue 2: date_formatter.dart
sed -i 's/} catch (e) {/} catch (e, s) {/g' lib/core/utils/date_formatter.dart

# issue 3: secure_storage_service.dart
sed -i 's/} catch (_) {/} catch (e, s) {/g' lib/core/services/secure_storage_service.dart

# issue 4: upi_service.dart
sed -i 's/} catch (e) {/} catch (e, s) {/g' lib/core/services/upi_service.dart
