import { HelloPageBuilder } from './Helloworld';

class navigationParams {
  pathStack: NavPathStack = new NavPathStack();
  boo: boolean = true;
}

class URL {
  url: string = '';
}

@Builder
function navigationAction(params: navigationParams) {
  Column() {
    Navigation(params.pathStack) {
      Button('router to page', { stateEffect: true, type: ButtonType.Capsule })
        .width('80%')
        .height(40)
        .margin(20)
        .onClick(() => {
          // 通过修改@BuilderParam参数决定是否跳转。
          if (params.boo) {
            params.pathStack.pushPath({ name: 'HelloWorldPage' });
          } else {
            console.info('@BuilderParam setting does not jump');
          }
        })
    }
    .navDestination(HelloPageBuilder)
    .hideTitleBar(true)
    .height('100%')
    .width('100%')
  }
  .height('25%')
  .width('100%')
}

@Builder
function imageEdge(src: URL) {
  Image(src.url)
    .height(100)
    .width('60%')
    .margin('5')
}
@Builder
function imagePing(src: URL) {
  Image(src.url)
    .height(200)
    .width('80%')
}

const globalBuilder : WrappedBuilder<[navigationParams]> = wrapBuilder(navigationAction);
const imageBuilder: WrappedBuilder<[URL]>[] = [wrapBuilder(imageEdge), wrapBuilder(imagePing)];


@Entry
@Component
struct ParentPage {
  @State info: navigationParams = new navigationParams();
  scroller: Scroller = new Scroller();
  @State url: string = "https://haowallpaper.com/link/common/file/getCroppingImg/17424727189736832";
  build() {
    Scroll(this.scroller) {
      Column() {
        Text('ParentPage')
        navigationAction({ pathStack: this.info.pathStack, boo: true })
        ChildPageOne()
        ChildPage_BuilderParam({ eventBuilder: navigationAction })

        Divider()
        globalBuilder.builder({pathStack: this.info.pathStack, boo: true})
        ForEach(imageBuilder, (item: WrappedBuilder<[URL]>) => {
          item.builder({url: this.url})
        })
        Button('切换图片')
          .onClick(() => {
            this.url = 'https://haowallpaper.com/link/common/file/getCroppingImg/17414408731020672'
          })
      }
      .width('100%')
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.On) // 滚动条常驻显示
    .scrollBarColor(Color.Gray) // 滚动条颜色
    .scrollBarWidth(10) // 滚动条宽度
  }
}

@Component
struct ChildPageOne {
  @State info: navigationParams = new navigationParams();

  build() {
    Column() {
      Text('ChildPage')
      navigationAction({ pathStack: this.info.pathStack, boo: true })
    }
  }
}

@Component
struct ChildPage_BuilderParam {
  @State info: navigationParams = new navigationParams();
  @BuilderParam eventBuilder: (param: navigationParams) => void = navigationAction;

  build() {
    Column() {
      Text('ChildPage_BuilderParam')
      // 对传递过来的全局@Builder进行参数修改，可以实现禁用点击跳转的功能。
      this.eventBuilder({ pathStack: this.info.pathStack, boo: false })
    }
  }
}