import {WrappedBuilderComponent} from './LearnFancy'


@Entry
@Component
struct NavigationExample {
  @State TooTmp: ToolbarItem = {'value': "func", 'icon': "./image/ic_public_highlights.svg", 'action': ()=> {}}
  private arr: number[] = [1, 2, 3];

  build() {
    Column() {
      Navigation() {
        TextInput({ placeholder: 'search...' })
          .width("90%")
          .height(40)
          .backgroundColor('#FFFFFF')

        List({ space: 12 }) {
          ForEach(this.arr, (item:string) => {
            ListItem() {
              NavRouter() {
                Text("NavRouter" + item)
                  .width("100%")
                  .height(72)
                  .backgroundColor('#FFFFFF')
                  .borderRadius(24)
                  .fontSize(16)
                  .fontWeight(500)
                  .textAlign(TextAlign.Center)
                NavDestination() {
                  WrappedBuilderComponent()
                }
                .title("NavDestinationTitle" + item)
              }
            }
          }, (item:string):string => item)
        }
        .width("90%")
        .margin({ top: 12 })
      }
      .title("主标题")
      .mode(NavigationMode.Split)
      .menus([
        {value: "", icon: "./image/ic_public_search.svg", action: ()=> {}},
        {value: "", icon: "./image/ic_public_add.svg", action: ()=> {}},
        {value: "", icon: "./image/ic_public_add.svg", action: ()=> {}},
        {value: "", icon: "./image/ic_public_add.svg", action: ()=> {}},
        {value: "", icon: "./image/ic_public_add.svg", action: ()=> {}}
      ])
      .toolbarConfiguration([this.TooTmp, this.TooTmp, this.TooTmp])
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F1F3F5')
  }
}
