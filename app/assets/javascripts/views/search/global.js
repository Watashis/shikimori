import { bind } from 'decko';
import URI from 'urijs';
import Turbolinks from 'turbolinks';

import View from 'views/application/view';

import AutocompleteEngine from './autocomplete_engine';
import IndexEngine from './index_engine';

import globalHandler from 'helpers/global_handler';
import JST from 'helpers/jst';

const VARIANT_SELECTOR = '.b-db_entry-variant-list_item';
const ITEM_SELECTOR = `${VARIANT_SELECTOR}, .search-mode`;

export default class GlobalSearch extends View {
  isActive = false

  initialize() {
    this.$input = this.$('.field input');

    this.phrase = this.inputSearchPhrase;
    this.currentMode = this.hasIndex ? 'index' : 'anime';

    this.globalTryCloseOnFocus = this._tryCloseOnFocus.bind(this);

    globalHandler.on('slash', this._onGlobalSlash);

    this.$input
      .on('focus', () => this._activate())
      .on('change blur paste keyup', () => this.phrase = this.inputSearchPhrase);

    this.$('.field .clear')
      .on('click', () => this._clearPhrase(true));

    this.$content
      .on('click', '.search-mode', ({ currentTarget }) => {
        this._selectItem(currentTarget);
        this.$input.focus();
      })
      .on('mousemove', VARIANT_SELECTOR, ({ currentTarget }) => {
        // better than mouseover cause it does not trigger after keyboard scroll
        if (this.currentItem !== currentTarget) {
          this._selectItem(currentTarget, false);
        }
      });
  }

  get hasIndex() {
    return !!$('.b-search-results').length;
  }

  get currentMode() {
    return this._currentMode;
  }

  get isIndexMode() {
    return this.currentMode === 'index';
  }

  set currentMode(value) {
    this._currentMode = value;

    if (this.isIndexMode) {
      this.searchEngine = new IndexEngine();
    } else {
      this.searchEngine = new AutocompleteEngine(
        this.$node.data(`autocomplete_${this.currentMode}_url`),
        this.$content
      );
    }
  }

  get $content() {
    return this.$root.find('.search-results');
  }

  get $activeItem() {
    return this.$content.find(ITEM_SELECTOR).filter('.active');
  }

  get isSearching() {
    return !Object.isEmpty(this.phrase);
  }

  get phrase() {
    return this._phrase;
  }

  set phrase(value) {
    const trimmedValue = value.trim();
    const priorPhrase = this._phrase;

    if (this._phrase === trimmedValue) { return; }

    this._phrase = trimmedValue;
    if (this.$input[0].value !== value) {
      this.$input[0].value = value;
    }

    this.$input.toggleClass('has-value', !Object.isEmpty(this.phrase));

    if (priorPhrase === undefined) { return; }

    if (this.phrase) { // it is undefined in constructor
      this.searchEngine.search(this.phrase);
      //   this._activate();
      //   this.debouncedSearch(this.phrase);
    } else {
      this.searchEngine.cancel();
      this._renderModes();
    }

    this._toggleGlobalSearch();
  }

  get inputSearchPhrase() {
    return this.$input.val().trim();
  }

  cancel() {
    this._deactivate();

    // if (Object.isEmpty(this.phrase)) {
    //   this._deactivate();
    // } else {
    //   this._clearPhrase();
    // }
  }

  // private functions
  _activate() {
    if (this.isActive) { return; }

    this.isActive = true;
    this._toggleGlobalSearch();

    this._renderModes();

    globalHandler
      .on('enter', this._onEnter)
      .on('up', this._onMoveUp)
      .on('down', this._onMoveDown)
      .on('esc', this._onEsc);

    $(document.body).on('focus', '*', this.globalTryCloseOnFocus);
    $(document).one('turbolinks:before-cache', () => {
      $(document.body).off('focus', '*', this.globalTryCloseOnFocus);
    });
  }

  _deactivate() {
    if (!this.isActive) { return; }

    this.isActive = false;
    this._toggleGlobalSearch();

    if (this.$input.is(':focus')) {
      this.$input.blur();
    }

    globalHandler
      .off('enter', this._onEnter)
      .off('esc', this._onEsc)
      .off('up', this._onMoveUp)
      .off('down', this._onMoveDown);

    $(document.body).off('focus', '*', this.globalTryCloseOnFocus);
  }

  _renderModes() {
    this.$content.html(
      JST['search/options']({
        currentMode: this.currentMode,
        hasIndex: this.hasIndex
      })
    );
  }

  _clearPhrase(isFocus) {
    this.phrase = '';

    if (isFocus) {
      this.$input.focus();
    }
  }

  _selectItem(node, doScroll) {
    this._deselectItems();

    if (this.isSearching) {
      this.currentItem = node;
    } else {
      this.currentMode = $(node).data('mode');
    }

    const $node = $(node);
    $node.addClass('active');

    if (doScroll) {
      this._scrollToItem($node);
    }
  }

  _deselectItems() {
    this.$content.find(ITEM_SELECTOR).removeClass('active');
  }

  _scrollToItem($node) {
    // let didScroll = false;

    const nodeTop = $node.offset().top;
    const nodeHeight = $node.outerHeight();

    const windowTop = window.scrollY || document.documentElement.scrollTop;
    const windowHeight = $(window).height();

    if (nodeTop < windowTop) {
      // didScroll = true;
      if ($node.is(':first-child')) {
        window.scrollTo(0, 0);
      } else {
        window.scrollTo(0, nodeTop - 10);
      }
    } else if (nodeTop + nodeHeight > windowTop + windowHeight) {
      // didScroll = true;
      window.scrollTo(0, windowTop + (nodeTop + nodeHeight) - (windowTop + windowHeight) + 10);
    }

    // NOTE: no need in it after switching from mouseover to mousemove
    // to prevent item selection by mouseover event
    // it could happen if mouse cursor currently is over some item
    // if (didScroll) {
    //   document.body.style.pointerEvents = 'none';

    //   if (!this.debouncedEnableMouseEvents) {
    //     this.debouncedEnableMouseEvents = debounce(250, () => (
    //       document.body.style.pointerEvents = ''
    //     ));
    //   }
    //   this.debouncedEnableMouseEvents();
    // }
  }

  _toggleGlobalSearch() {
    const isEnabled = this.isActive && (
      !this.isIndexMode ||
        (this.isIndexMode && Object.isEmpty(this.phrase))
    );

    $('.l-top_menu-v2').toggleClass('is-global-search', isEnabled);

    if (!this._bindedDeactivate) {
      this._bindedDeactivate = this._deactivate.bind(this);
    }
    $('.b-shade').off('click', this._bindedDeactivate);
    if (isEnabled) {
      $('.b-shade').on('click', this._bindedDeactivate);
    }
  }

  @bind
  _onGlobalSlash(e) {
    const target = e.target || e.srcElement;
    const isIgnored = target.isContentEditable ||
      target.tagName === 'INPUT' ||
      target.tagName === 'SELECT' ||
      target.tagName === 'TEXTAREA';

    if (isIgnored) { return; }

    e.preventDefault();
    e.stopImmediatePropagation();

    this.$input.focus();
    this.$input[0].setSelectionRange(0, this.$input[0].value.length);
  }

  @bind
  _onEnter(e) {
    if (this.isIndexMode) { return; }
    if (!this.phrase.trim()) { return; }
    e.preventDefault();
    e.stopImmediatePropagation();

    let url;

    if (this.$activeItem.length) {
      url = this.$activeItem.find('a').first().attr('href');
    } else {
      url =
        URI(this.$node.data(`search_${this.currentMode}_url`))
          .addQuery({ search: this.phrase });
    }

    Turbolinks.visit(url);
  }

  @bind
  _onEsc(e) {
    e.preventDefault();
    e.stopImmediatePropagation();

    this.cancel();
  }

  @bind
  _onMoveUp(e) {
    const { $activeItem } = this;
    const item = $activeItem.prev()[0];

    if (this.isActive) {
      e.preventDefault();
      e.stopImmediatePropagation();
    }

    if (item) {
      this._selectItem(item, true);
    } else if (this.isSearching) {
      this._deselectItems();
      this.$input.focus();
    }
  }

  @bind
  _onMoveDown(e) {
    const { $activeItem } = this;
    const item = $activeItem.length ?
      $activeItem.next()[0] :
      this.$content.find(ITEM_SELECTOR).first()[0];

    if (this.isActive) {
      e.preventDefault();
      e.stopImmediatePropagation();
    }

    if (item) {
      this._selectItem(item, true);
    }
  }

  _tryCloseOnFocus({ target }) {
    const $target = $(target);
    const isInside = target === this.root || $target.closest(this.$root).length;

    if (isInside || !$target.parents('html').length) { return; }

    this._deactivate();
  }
}
