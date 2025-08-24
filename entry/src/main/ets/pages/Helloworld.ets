@Builder
export function HelloPageBuilder() {
  HellowWorldPage()
}


@Component
struct HellowWorldPage {
  @State message: string  = 'Hello World';
  @State pathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column() {
        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .height('100%')
  }
}