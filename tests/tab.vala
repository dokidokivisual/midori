/*
 Copyright (C) 2012 Christian Dywan <christian@twotoasts.de>

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 See the file COPYING for the full license text.
*/

void tab_load_title () {
    /*
    var view = new Midori.View.with_title ();
    view.set_uri ("about:blank");
    do {
    }
    while (view.load_status != Midori.LoadStatus.FINISHED);
    Katze.assert_str_equal ("about:blank", "about:blank", view.uri);
    Katze.assert_str_equal ("about:blank", "", view.get_display_uri ()); */
}

struct TestCaseEllipsize {
    public string uri;
    public string? title;
    public Pango.EllipsizeMode expected_ellipsize;
    public string expected_title;
}

const TestCaseEllipsize[] titles = {
    { "http://secure.wikimedia.org/wikipedia/en/wiki/Cat",
      "Cat - Wikipedia, the free encyclopedia",
      Pango.EllipsizeMode.END, null },
    { "https://ar.wikipedia.org/wiki/%D9%82%D8%B7",
      "قط - ويكيبيديا، الموسوعة الحرة",
      Pango.EllipsizeMode.END, null },
    { "https://ar.wikipedia.org/wiki/قط",
      "قط - ويكيبيديا، الموسوعة الحرة",
      Pango.EllipsizeMode.END, null },
    { "http://help.duckduckgo.com/customer/portal/articles/352255-wordpress",
      "DuckDuckGo | WordPress",
      Pango.EllipsizeMode.START, null },
    { "file:///home/user",
      "OMG!",
      Pango.EllipsizeMode.START, "/home/user" },
    { "http://paste.foo/0007-Bump-version-to-0.4.7.patch",
      null,
      Pango.EllipsizeMode.START, "0007-Bump-version-to-0.4.7.patch" },
    { "http://translate.google.com/#en/de/cat%0Adog%0Ahorse",
      "Google Translator",
      Pango.EllipsizeMode.END, null }
};

static void tab_display_title () {
    foreach (var title in titles) {
        string result = Midori.Tab.get_display_title (title.title, title.uri);
        string expected = title.expected_title ?? "‪" + title.title;
        if (result != expected)
            error ("%s expected for %s but got %s",
                   expected, title.title, result);
    }
}

static void tab_display_ellipsize () {
    foreach (var title in titles) {
        Pango.EllipsizeMode result = Midori.Tab.get_display_ellipsize (
            Midori.Tab.get_display_title (title.title, title.uri), title.uri);
        if (result != title.expected_ellipsize)
            error ("%s expected for %s/ %s but got %s",
                   title.expected_ellipsize.to_string (), title.title, title.uri, result.to_string ());
    }
}

void tab_special () {
    var browser = new Gtk.Window (Gtk.WindowType.TOPLEVEL);
    /*
    var dial = new Midori.SpeedDial ("/", null);
    var settings = new Midori.WebSettings ();
    var browser = new Midori.Browser ();
    browser.set ("speed-dial", dial, "settings", settings);
    */
    var tab = new Midori.View.with_title ();
    browser.add (tab);
    /* browser.add_tab (tab); */
    var loop = MainContext.default ();

    /* tab.set_uri ("about:blank"); */
    do { loop.iteration (true); } while (tab.load_status != Midori.LoadStatus.FINISHED);
    assert (tab.is_blank ());
    assert (!tab.can_view_source ());
    /* FIXME assert (tab.special); */
    assert (!tab.can_save ());

    tab.set_uri ("about:private");
    do { loop.iteration (true); } while (tab.load_status != Midori.LoadStatus.FINISHED);
    assert (tab.is_blank ());
    assert (!tab.can_view_source ());
    assert (tab.special);
    assert (!tab.can_save ());

    tab.set_uri ("error:nodocs file:///some/docs/path");
    do { loop.iteration (true); } while (tab.load_status != Midori.LoadStatus.FINISHED);
    assert (!tab.is_blank ());
    assert (!tab.can_view_source ());
    assert (tab.special);
    assert (!tab.can_save ());

    tab.set_uri ("http://.invalid");
    do { loop.iteration (true); } while (tab.load_status != Midori.LoadStatus.FINISHED);
    assert (!tab.is_blank ());
    assert (!tab.can_view_source ());
    assert (tab.special);
    assert (!tab.can_save ());

    var item = tab.get_proxy_item ();
    item.set_meta_integer ("delay", Midori.Delay.UNDELAYED);
    tab.set_uri ("http://example.com");
    do { loop.iteration (true); } while (tab.load_status != Midori.LoadStatus.FINISHED);
    /* FIXME assert (!tab.can_view_source ()); */
    /* FIXME assert (tab.special); */
    /* FIXME assert (!tab.can_save ()); */

    /* FIXME use an HTTP URI that's available even offline */
    tab.set_uri ("http://example.com");
    do { loop.iteration (true); } while (tab.load_status != Midori.LoadStatus.FINISHED);
    assert (!tab.is_blank ());
    assert (tab.can_view_source ());
    assert (!tab.special);
    assert (tab.can_save ());
    tab.destroy ();

    /* Mimic browser: SourceView with no external editor */
    var source = new Midori.View.with_title ();
    browser.add (source);
    source.web_view.set_view_source_mode (true);
    source.web_view.load_uri ("http://example.com");
    do { loop.iteration (true); } while (source.load_status != Midori.LoadStatus.FINISHED);
    assert (!source.is_blank ());
    assert (!source.can_view_source ());
    /* FIXME assert (!source.special); */
    /* FIXME assert (source.can_save ()); */
    assert (source.web_view.get_view_source_mode ());

    source.set_uri ("http://.invalid");
    do { loop.iteration (true); } while (source.load_status != Midori.LoadStatus.FINISHED);
    assert (!source.is_blank ());
    assert (!source.can_view_source ());
    assert (source.special);
    assert (!source.can_save ());
    assert (!source.web_view.get_view_source_mode ());
}

void main (string[] args) {
    Test.init (ref args);
    Midori.App.setup (ref args, null);
    Midori.Paths.init (Midori.RuntimeMode.NORMAL, null);
    WebKit.get_default_session ().set_data<bool> ("midori-session-initialized", true);
    Test.add_func ("/tab/load-title", tab_load_title);
    Test.add_func ("/tab/display-title", tab_display_title);
    Test.add_func ("/tab/ellipsize", tab_display_ellipsize);
    Test.add_func ("/tab/special", tab_special);
    Test.run ();
}
