pkgname=xgui4-dev-scripts
pkgver=0.0.1
pkgrel=1
pkgdesc="Scripts utiles pour les développeurs ou utilisateurs avancés"
arch=('x86_64') 
license=('MIT')
source=("unsafe-detector.sh") 
sha256sums=('SKIP')

package() {
    install -Dm755 "$srcdir/unsafe-detector.sh" "$pkgdir/usr/bin/unsafe-detector.sh"
}
