#!/bin/bash

####################################################################################################
####################################################################################################
####################################################################################################
###### Get token secret ###############################################
####################################################################################################
####################################################################################################
####################################################################################################

CONSUL_KV_TOKEN_FILE="/run/secrets/CONSUL_KV_TOKEN"
CONSUL_KV_URL_FILE="/run/secrets/CONSUL_KV_URL"

if [ ! -f "$CONSUL_KV_URL_FILE" ]; then
  echo "Ошибка: Файл $CONSUL_KV_URL_FILE не найден."
  exit 1
fi

if [ ! -f "$CONSUL_KV_TOKEN_FILE" ]; then
  echo "Ошибка: Файл $CONSUL_KV_TOKEN_FILE не найден."
  exit 1
fi

CONSUL_KV_TOKEN=$(cat $CONSUL_KV_TOKEN_FILE)
CONSUL_KV_URL=$(cat $CONSUL_KV_URL_FILE)

#echo "CONSUL_KV_TOKEN: $CONSUL_KV_TOKEN"
#echo "CONSUL_KV_URL: $CONSUL_KV_URL"

if [ -z "$CONSUL_KV_TOKEN" ]; then
  echo "Ошибка: Не задан токен для доступа к Consul."
  exit 1
fi

if [ -z "$CONSUL_KV_URL" ]; then
  echo "Ошибка: Не задан url для доступа к Consul."
  exit 1
fi

####################################################################################################
####################################################################################################
####################################################################################################
###### Получение настроек с удаленного сервера ###############################################
####################################################################################################
####################################################################################################
####################################################################################################

if [ -z "$CONSUL_KV_URL" ]; then
  echo "Ошибка: Не задан url к данным в Consul."
  exit 1
fi

KV_URL="$CONSUL_KV_URL?token=$CONSUL_KV_TOKEN"

# Получение конфигурационных данных из Consul
response=$(curl -sS --write-out "\n%{http_code}" --request GET --url "$KV_URL")
status_code=$(echo "$response" | tail -n1)
config_data=$(echo "$response" | head -n -1)

# Проверка кода ответа
if [[ "$status_code" != "200" ]]; then
  echo "Ошибка: Не удалось получить конфигурационные данные из Consul. Код ответа: $status_code сообщение: $response"
  exit 1
fi

# Проверка наличия данных
if [[ -z "$config_data" ]]; then
  echo "Ошибка: Не удалось получить конфигурационные данные из Consul."
  exit 1
fi

# Извлечение значения из JSON
config_value=$(echo "$config_data" | jq -r '.[0].Value')

# Декодирование значения из base64
decoded_config=$(echo "$config_value" | base64 -d)

####################################################################################################
#### Сохранение токена ####################################################################################
####################################################################################################

mkdir -p /mnt/data
echo $decoded_config >/mnt/data/consul.json

exec docker-entrypoint.sh "$@"
