---
paths:
  - "**/*.xaml"
  - "**/*.xaml.cs"
  - "**/*ViewModel.cs"
---

# XAML App Conventions

Applies to XAML markup, its code-behind, and the view models bound to it.
The C# in those files also follows [coding-csharp.md](coding-csharp.md).

If a project-scope `.claude/rules/coding-xaml.md` exists, that file
supersedes this one.

**Check the framework before applying a line.** WinUI 3, UWP, WPF and
.NET MAUI all use `.xaml`, and they differ in exactly the places this
rule covers — WPF has no `{x:Bind}` at all. The project file says which
one: `<UseWinUI>`, `<UseWPF>` or `<UseMaui>`. Lines specific to one
framework say so; unlabelled lines hold across all of them.

The `*ViewModel.cs` glob is a naming heuristic, not a guarantee. It
matches the view-model convention Microsoft's MVVM docs use, and a view
model named anything else loads this rule only once a `.xaml` file has
been read.

## Binding (WinUI, UWP)

- **`{x:Bind}` over `{Binding}`.** It compiles to code, so a wrong path
  fails the build instead of failing silently at runtime, and it is
  faster. Keep `{Binding}` for the cases `{x:Bind}` cannot express.
- **`{x:Bind}` defaults to `OneTime`; `{Binding}` defaults to
  `OneWay`.** Anything bound to a value that changes needs
  `Mode=OneWay` or `Mode=TwoWay` spelled out. A missing mode compiles
  cleanly and then the UI just never updates — the most common
  `{x:Bind}` bug, per Microsoft's own migration guide. Write the mode on
  each binding rather than setting `x:DefaultBindMode` on an ancestor,
  so the binding can be read on its own.
- The `{x:Bind}` path is rooted at the page or window, not at
  `DataContext`. Expose the view model as a typed property on the page
  (`public MainViewModel ViewModel { get; }`) and bind through it.
  Inside a `DataTemplate`, `{x:Bind}` needs `x:DataType`.
- A two-way binding on `TextBox.Text` pushes to the source on
  `LostFocus`, not per keystroke. Add
  `UpdateSourceTrigger=PropertyChanged` when the view model has to see
  each edit (live validation, search-as-you-type).

## Resources (WinUI, UWP)

- **`{ThemeResource}` for anything that differs between light, dark and
  high contrast; `{StaticResource}` for everything else.** A static
  reference is resolved once at load, so a brush wired that way keeps
  its startup color after the user switches theme.
- Theme dictionaries define every key for `Light`, `Dark` and
  `HighContrast` alike. A key missing from one theme fails at the moment
  that theme is selected, not at startup.
- Put resources at the narrowest scope that uses them: page resources
  for one page, `App.xaml` only for what is genuinely app-wide.

## Code-behind

- **Code-behind holds view-only logic**: focus, animation, visual
  states, wiring a control's events through to the view model. Data
  access, business rules and anything a test would want to exercise
  belong in the view model or a service behind it.
- **A page is constructed by the framework, not the container.**
  `Frame.Navigate` takes the page's `Type` and creates the page itself,
  so the page cannot receive constructor arguments. Resolve its view
  model from the container in the page's constructor. That is the one
  service-locator call coding-csharp.md allows. Pass per-navigation data
  as the `Navigate` parameter and read it in `OnNavigatedTo`, never
  through a static.

## Threading

- **Controls, and any `ObservableCollection<T>` bound to one, are touched
  on the UI thread only.** From elsewhere, marshal the change with
  `DispatcherQueue.TryEnqueue` (WinUI 3; UWP's `CoreDispatcher` does not
  work there). Capture the `DispatcherQueue` on the UI thread, in the
  constructor, and store it. There is no global "main window"
  dispatcher to fetch later from a background thread.
- `TryEnqueue` returns `false` when the work was not queued, for example
  while the queue is shutting down. Ignoring that result drops the
  update silently.
- **`await` does not move work off the UI thread.** An `async` handler
  runs on the UI thread until it reaches an incomplete await, and so
  does the code after it. CPU-bound work goes through `Task.Run`.

## MVVM Toolkit

These apply where `CommunityToolkit.Mvvm` is referenced.

- **New observable members use the generators.** Use
  `[ObservableProperty]` and `[RelayCommand]`, not hand-written
  `INotifyPropertyChanged`, and never both styles in one class.
  Hand-written classes that already exist stay as they are until they
  are changed for a real reason.
- **`[ObservableProperty]` goes on a partial property, not a field:**
  `[ObservableProperty] public partial string? Name { get; set; }`. On a
  field it raises MVVMTK0045 in WinUI and UWP. That code is not AOT
  compatible in WinRT scenarios, because the CsWinRT generators cannot
  see a property produced from a field. If MVVMTK0041 fires, the
  project's `LangVersion` is too old for partial properties. The
  toolkit's docs name `preview` as the fix; do not remove
  `[ObservableProperty]` to make the diagnostic go away.
- An observable class must be `partial`, and so must every type it is
  nested in, or the generator cannot emit its half.
