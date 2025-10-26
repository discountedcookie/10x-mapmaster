# Changelog

## 1.0.0 (2025-10-26)


### Features

* add comprehensive quality and security tooling ([749bb32](https://github.com/discountedcookie/10x-mapmaster/commit/749bb321b1652b2ed851639b35257d9c19b91578))
* add minimal Claude commands for ConPort workflow ([8a18ae4](https://github.com/discountedcookie/10x-mapmaster/commit/8a18ae46676780f4e47c7da6496e9f3a25267250))
* add test coverage reporting with Codecov ([be09802](https://github.com/discountedcookie/10x-mapmaster/commit/be098024fec211648d9ebce1f3c3432319eef212))
* complete migration to minimal context workflow ([1d6ecc0](https://github.com/discountedcookie/10x-mapmaster/commit/1d6ecc077cbbe86c8e6116d8ce2b381007619ce1))
* Complete UI/UX redesign with modern game interface ([8e3bf46](https://github.com/discountedcookie/10x-mapmaster/commit/8e3bf46ff941ccd69970ae50e605bef87b88a31e))
* **game:** add game composables - useGameState, useGameValidation, useGameActions, useGameFlow ([ca7b463](https://github.com/discountedcookie/10x-mapmaster/commit/ca7b4630841f747b0d6d913b9545783cfb71bbd7))
* **game:** add GameStartScreen, GameResumeDialog, and GameLoadingOverlay components ([80a48d9](https://github.com/discountedcookie/10x-mapmaster/commit/80a48d929de911ddcf3167a3c5e88eb627e449c0))
* implement percentile normalization and fix map state management ([2ee0090](https://github.com/discountedcookie/10x-mapmaster/commit/2ee0090c41547044ddbbc9c80b9b0d552941670d))
* initialize ConPort for context management ([5e741bb](https://github.com/discountedcookie/10x-mapmaster/commit/5e741bb232f9bc1830d16148f105caa1837d51cd))
* Major UI improvements and internationalization support ([a059c25](https://github.com/discountedcookie/10x-mapmaster/commit/a059c2580647b4e76ab3e51971ee099f3eb1a713))
* **map:** add useMapMarkers and useMapBounds composables ([bb35382](https://github.com/discountedcookie/10x-mapmaster/commit/bb353820646ddebb8f15bead2311f50e677913f1))
* test minimal context workflow and set up worktree structure ([2f2413e](https://github.com/discountedcookie/10x-mapmaster/commit/2f2413efa6449d5463b7bd0f3b5070b7de56fce6))
* track ConPort project memory with repository ([f0b35c9](https://github.com/discountedcookie/10x-mapmaster/commit/f0b35c93a7a6607d05fb06067d0ba67b9f35859c))
* **workflow:** implement Cline-native memory system ([9a34fa1](https://github.com/discountedcookie/10x-mapmaster/commit/9a34fa1eedcdcb97b0c130dc08ff05249c633627))


### Bug Fixes

* access .value property on Ref in event handler ([1bbc803](https://github.com/discountedcookie/10x-mapmaster/commit/1bbc8037aeb47005080e3fe79c39eabc03b6ec84))
* add missing i18n keys to all locales and fix GameView template types ([1ef4836](https://github.com/discountedcookie/10x-mapmaster/commit/1ef4836760106674fded4c67bead6c8ce5513144))
* **docs:** correct entity count discrepancy in memory-audit.md ([c3898fd](https://github.com/discountedcookie/10x-mapmaster/commit/c3898fd61544d4f0d0359e211cba4497dfb7bfc4))
* **game:** properly handle reactive properties in GameView template ([d2d0675](https://github.com/discountedcookie/10x-mapmaster/commit/d2d06751dc4c25540f04a58912d29e2a65782db6))
* **i18n:** add missing game question card translation keys ([29ba282](https://github.com/discountedcookie/10x-mapmaster/commit/29ba2829e7258704a53a6d028bb7e1587d5d2de1))
* **map:** fix NaN bounds error and implement proper state switching between home and game views ([06b74f8](https://github.com/discountedcookie/10x-mapmaster/commit/06b74f84d3fb413fa92cb3aac13954ae890cbdac))
* **map:** restore clustering and placesGeoJson for browse mode ([50cab55](https://github.com/discountedcookie/10x-mapmaster/commit/50cab5511449edbfa00e7376c8968e9dfb3768b6))
* Refactor metadata filtering with property path fallback ([d15713a](https://github.com/discountedcookie/10x-mapmaster/commit/d15713af4d0b26ee69008e58ba5c78b55e98f990))
* remove unused ref import from useMapState ([d1f1619](https://github.com/discountedcookie/10x-mapmaster/commit/d1f16195d335025e0bfb8a755170c7c66c4c31fb))
* replace isNaN with Number.isNaN in GameView ([6cdae36](https://github.com/discountedcookie/10x-mapmaster/commit/6cdae36db657794756c830a623f653424d85ce3c))
* resolve unit test failures in places store ([959518e](https://github.com/discountedcookie/10x-mapmaster/commit/959518e02aecd52b9ee9e3945ef9720d8c1653c5))
* wrap event handlers to properly handle Ref assignments ([7ee8655](https://github.com/discountedcookie/10x-mapmaster/commit/7ee865562e1ac5347d8e540925705cf9ca898730))
