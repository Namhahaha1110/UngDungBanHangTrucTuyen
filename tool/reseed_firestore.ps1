$ErrorActionPreference = "Stop"

function Get-FirebaseAccessToken {
  $configPath = Join-Path $HOME ".config\configstore\firebase-tools.json"
  $config = Get-Content $configPath -Raw | ConvertFrom-Json

  $expiresAt = [int64]$config.tokens.expires_at
  $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  if ($expiresAt -gt ($now + 60000)) {
    return $config.tokens.access_token
  }

  $clientId = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
  $clientSecret = "j9iVZfS8kkCEFUPaAeJV0sAi"
  $refreshToken = $config.tokens.refresh_token

  $body = @{
    client_id = $clientId
    client_secret = $clientSecret
    refresh_token = $refreshToken
    grant_type = "refresh_token"
  }

  $tokenResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "https://oauth2.googleapis.com/token" `
    -Body $body `
    -ContentType "application/x-www-form-urlencoded"

  $config.tokens.access_token = $tokenResponse.access_token
  $config.tokens.expires_in = $tokenResponse.expires_in
  $config.tokens.token_type = $tokenResponse.token_type
  $config.tokens.expires_at = [DateTimeOffset]::UtcNow.AddSeconds([int]$tokenResponse.expires_in).ToUnixTimeMilliseconds()
  $config | ConvertTo-Json -Depth 20 | Set-Content -Encoding utf8 $configPath

  return $tokenResponse.access_token
}

function Convert-ToFirestoreValue {
  param([Parameter(Mandatory = $true)] $Value)

  if ($null -eq $Value) { return @{ nullValue = $null } }
  if ($Value -is [string]) { return @{ stringValue = $Value } }
  if ($Value -is [bool]) { return @{ booleanValue = $Value } }
  if ($Value -is [int] -or $Value -is [long]) { return @{ integerValue = "$Value" } }
  if ($Value -is [double] -or $Value -is [float] -or $Value -is [decimal]) { return @{ doubleValue = $Value } }
  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    $values = @()
    foreach ($item in $Value) {
      $values += ,(Convert-ToFirestoreValue -Value $item)
    }
    return @{ arrayValue = @{ values = $values } }
  }
  if ($Value -is [System.Collections.IDictionary] -or $Value -is [hashtable]) {
    $fields = @{}
    foreach ($key in $Value.Keys) {
      $fields[$key] = Convert-ToFirestoreValue -Value $Value[$key]
    }
    return @{ mapValue = @{ fields = $fields } }
  }

  return @{ stringValue = [string]$Value }
}

function New-Write {
  param(
    [Parameter(Mandatory = $true)][string]$Collection,
    [Parameter(Mandatory = $true)][string]$DocumentId,
    [Parameter(Mandatory = $true)][hashtable]$Map
  )

  $fields = @{}
  foreach ($key in $Map.Keys) {
    $fields[$key] = Convert-ToFirestoreValue -Value $Map[$key]
  }

  return @{
    update = @{
      name = "projects/appshoppe-260329/databases/(default)/documents/$Collection/$DocumentId"
      fields = $fields
    }
  }
}

$categories = @(
  @{ id = "men"; name = "Thời Trang Nam"; image = "category_men.png" },
  @{ id = "women"; name = "Thời Trang Nữ"; image = "category_women.png" },
  @{ id = "kids"; name = "Thời Trang Em Bé"; image = "category_kids.png" },
  @{ id = "beauty"; name = "Vẻ đẹp & Sang trọng"; image = "category_beauty.png" },
  @{ id = "home"; name = "Nhà & Bếp"; image = "category_home.png" },
  @{ id = "toys"; name = "Đồ chơi & Trò chơi"; image = "category_toys.png" }
)

$products = @(
  @{
    id = "jeans_1"
    name = "Quần Jeans nam ống suông WHY NOT"
    price = 330650
    oldPrice = 550000
    image = "product_jeans.png"
    categoryId = "men"
    soldText = "Đã bán 1k+"
    description = "Quần jean màu xanh denim, form suông hiện đại, cạp cao tôn dáng, chất liệu dày dặn với đường may nổi tinh tế."
  },
  @{
    id = "hoodie_1"
    name = "HeaSmile áo nỉ nam cổ tròn basic"
    price = 217560
    oldPrice = 299000
    image = "product_hoodie.png"
    categoryId = "men"
    soldText = "Đã bán 600+"
    description = "Áo nỉ basic dễ phối, chất vải dày vừa, form trẻ trung."
  },
  @{
    id = "shirt_1"
    name = "Áo Thun - Classic Regular Tee"
    price = 210375
    oldPrice = 260000
    image = "product_shirt.png"
    categoryId = "women"
    soldText = "Đã bán 800+"
    description = "Áo thun form regular, mặc thường ngày thoải mái."
  },
  @{
    id = "powerbank_1"
    name = "USAMS Power Bank Sạc nhanh PD 20W"
    price = 295510
    oldPrice = 420000
    image = "product_powerbank.png"
    categoryId = "home"
    soldText = "Đã bán 300+"
    description = "Pin sạc dự phòng nhỏ gọn, hỗ trợ sạc nhanh PD 20W."
  }
)

$banners = @(
  @{ id = "banner_1"; image = "banner_1.png" },
  @{ id = "banner_2"; image = "banner_2.png" },
  @{ id = "banner_3"; image = "banner_3.png" }
)

$flashItems = @(
  @{ id = "flash_1"; image = "flash_1.png" },
  @{ id = "flash_2"; image = "flash_2.png" },
  @{ id = "flash_3"; image = "flash_3.png" },
  @{ id = "flash_4"; image = "flash_4.png" },
  @{ id = "flash_5"; image = "flash_5.png" },
  @{ id = "flash_6"; image = "flash_6.png" }
)

$writes = @()
foreach ($item in $categories) { $writes += ,(New-Write -Collection "categories" -DocumentId $item.id -Map $item) }
foreach ($item in $products) { $writes += ,(New-Write -Collection "products" -DocumentId $item.id -Map $item) }
foreach ($item in $banners) { $writes += ,(New-Write -Collection "banners" -DocumentId $item.id -Map $item) }
foreach ($item in $flashItems) { $writes += ,(New-Write -Collection "flashSale" -DocumentId $item.id -Map $item) }

$accessToken = Get-FirebaseAccessToken
$headers = @{
  Authorization = "Bearer $accessToken"
  "Content-Type" = "application/json; charset=utf-8"
}

$body = @{ writes = $writes } | ConvertTo-Json -Depth 30 -Compress
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

$response = Invoke-RestMethod `
  -Method Post `
  -Uri "https://firestore.googleapis.com/v1/projects/appshoppe-260329/databases/(default)/documents:commit" `
  -Headers $headers `
  -Body $bodyBytes

Write-Host "Updated $($writes.Count) Firestore documents."
Write-Host "Commit time: $($response.commitTime)"
