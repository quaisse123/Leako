$login = Invoke-RestMethod -Uri "http://84.235.230.47:8080/api/auth/login" -Method Post -ContentType "application/json" -Body (@{ email = "marouane@gmail.com"; motDePasse = "123" } | ConvertTo-Json) -TimeoutSec 30
$projets = Invoke-RestMethod -Uri "http://84.235.230.47:8080/api/projets?utilisateurId=$($login.userId)" -TimeoutSec 30
$p1 = $projets[0]
$campagnes = Invoke-RestMethod -Uri "http://84.235.230.47:8080/api/campagnes?projetId=$($p1.id)" -TimeoutSec 30
$allPhotos = @()
foreach ($c in $campagnes) {
    $fuites = Invoke-RestMethod -Uri "http://84.235.230.47:8080/api/fuites?campagneId=$($c.id)" -TimeoutSec 30
    foreach ($f in $fuites) {
        $photos = Invoke-RestMethod -Uri "http://84.235.230.47:8080/api/photos?fuiteId=$($f.id)" -TimeoutSec 30
        foreach ($p in $photos) {
            $allPhotos += [PSCustomObject]@{ id = $p.id; chemin = $p.cheminFichier; thumb = $p.thumbnailUrl }
        }
    }
}
Write-Host "Total photos: $($allPhotos.Count)"
$allPhotos | Group-Object chemin | ForEach-Object {
    Write-Host ("chemin={0} count={1} thumbs={2}" -f $_.Name, $_.Count, (($_.Group.thumb | Select-Object -Unique) -join ","))
}
