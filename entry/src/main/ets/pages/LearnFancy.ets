import PlayDetailViewModel from './Helloworld';


class URL {
  url: string = '';
}
@Builder
function imageEdge(src: URL) {
  Image(src.url)
    .imageFancy()
}
@Builder
function imagePing(src: URL) {
  Image(src.url)
    .imageFancy()
}

@Extend(Image)
function imageFancy() {
  .width('80%')
  .height(100)
  .alt('tupian')
  .margin(20)
}

const imageBuilder: WrappedBuilder<[URL]>[] = [wrapBuilder(imageEdge), wrapBuilder(imagePing)];

class Info {
  address: string = '天津';

  constructor(address: string) {
    this.address = address;
  }
}

class User {
  info: Info = new Info('杭州');
}

@Component
export struct WrappedBuilderComponent {
  @State url: string = "https://haowallpaper.com/link/common/file/getCroppingImg/17424727189736832";
  @State textColor: Color = Color.Red;
  @State textWidth: number = 80;
  @State switch: boolean = true;

  @Prop info: Info = new Info('北京');
  @State user: User = new User();

  @State vm: PlayDetailViewModel = new PlayDetailViewModel();

  aboutToAppear(): void {
    this.user.info = this.info;
  }

  build() {
    Column() {
      ForEach(imageBuilder, (item: WrappedBuilder<[URL]>) => {
        item.builder({url: this.url})
      })



      Text(`${this.info.address}`)
      Text(`${this.user.info.address}`)
      Button('点击')
        .onClick(() => {
          this.user.info = new Info('lasao')
          this.user.info.address = '上海';
        })

      Text(this.vm.coverUrl)
        .width(100)
        .height(100)
        .backgroundColor(this.vm.coverUrl)
      Row() {
        Button('点击改颜色')
          .onClick(() => {
            let self = this.vm;
            this.vm.changeCoverUrl(self);
          })
      }

      Button('1')
        .width(100)
        .height(100)
        .stateStyles({
          focused: {
            .backgroundColor('red')
          },
          pressed: {
            .backgroundColor('ff707070')
          },
          normal: {
            .backgroundColor('red')
          }
        })
        .onClick(() => {
          this.textWidth = this.textWidth == 80 ? 160: 80;
          this.switch = !this.switch;
        })

    }
  }
}