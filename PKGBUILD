# Maintainer: Marc barbier
pkgname=game-runner
pkgver=2.2
pkgrel=1
pkgdesc="Simple wrapper around envycontrol and optimus manager"
arch=('any')
url=''
license=('GPL2')
source=( 'gamerunner.sh'  'gamerunner.cfg' )
backup=( 'etc/gamerunner.cfg' )
optdepends=('optimus-manager: optimus-manager support'
            'envycontrol: envycontrol support'
            'supergfxctl: supergfxctl support' )

sha512sums=(
	'b073f717f83942dbb90a98e557b4e32a9e8d0ac1ebb94e753698278afa40333ec8168d0f0ffde7d60a4ac75e66f41c98ba0a56becb691712cd76e39886691fbc'
	'227fcebb72a73ff634278a61f07ef82e367bb9dc6f8bdd00a0fe774882b6c234421d1ef8639475e301820eb05ac9a4a3dc047c13875cc6f69d313f63c9e27c91'
)

package() {
  install -Dm 755 "$srcdir/gamerunner.sh" "$pkgdir/usr/bin/gamerunner"
  install -Dm 644 "$srcdir/gamerunner.cfg" "$pkgdir/etc/gamerunner.cfg"
}
